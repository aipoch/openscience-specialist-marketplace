#!/usr/bin/env python3
"""Adaptive Trial Simulator
Simulate adaptive clinical trial designs with support for interim analyses, sample size re-estimation, and early stopping rules"""

import argparse
import json
import math
import random
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Tuple, Callable, Optional
from enum import Enum
import numpy as np
from scipy import stats
from scipy.optimize import brentq


class DesignType(Enum):
    """adaptive design type"""
    GROUP_SEQUENTIAL = "group_sequential"
    ADAPTIVE_REESTIMATE = "adaptive_reestimate"
    DROP_THE_LOSER = "drop_the_loser"


class SpendingFunction(Enum):
    """Alpha consumption function"""
    OBRIEN_FLEMING = "obrien_fleming"
    POCOCK = "pocock"
    POWER_FAMILY = "power_family"


class ReestimateMethod(Enum):
    """Sample size re-estimation method"""
    PROMISING_ZONE = "promising_zone"
    CONDITIONAL_POWER = "conditional_power"
    INVERSE_NORMAL = "inverse_normal"


@dataclass
class TrialConfig:
    """Test configuration parameters"""
    design_type: DesignType = DesignType.GROUP_SEQUENTIAL
    n_simulations: int = 10000
    sample_size: int = 200  # Initial sample size per arm
    effect_size: float = 0.3  # Cohen's d
    alpha: float = 0.05
    power: float = 0.80
    interim_looks: int = 1
    spending_function: SpendingFunction = SpendingFunction.OBRIEN_FLEMING
    reestimate_method: ReestimateMethod = ReestimateMethod.PROMISING_ZONE

    # Revaluation parameters
    max_sample_size_multiplier: float = 2.0
    promising_zone_lower: float = 0.5  # Conditional power lower limit
    promising_zone_upper: float = 0.8  # Conditional power cap
    target_conditional_power: float = 0.9


@dataclass
class InterimResult:
    """Interim analysis results"""
    look_number: int
    cumulative_n: int
    z_score: float
    p_value: float
    test_statistic: float
    pooled_std: float
    stop_for_efficacy: bool = False
    stop_for_futility: bool = False
    continue_trial: bool = True
    new_sample_size: Optional[int] = None


@dataclass
class TrialResult:
    """Single simulation test results"""
    success: bool
    final_n: int
    stopped_early: bool
    stop_reason: Optional[str] = None  # "efficacy", "futility", None
    interim_results: List[InterimResult] = field(default_factory=list)
    p_value: float = 1.0
    z_score: float = 0.0


@dataclass
class SimulationSummary:
    """Simulation summary results"""
    success_rate: float
    type_i_error: float
    expected_sample_size: float
    early_stop_rate_efficacy: float
    early_stop_rate_futility: float
    avg_power: float
    interim_stop_rates: Dict[int, Dict[str, float]] = field(default_factory=dict)


class AlphaSpendingFunction:
    """Alpha consumption function implementation"""

    def __init__(self, spending_type: SpendingFunction, alpha: float):
        self.spending_type = spending_type
        self.alpha = alpha

    def cumulative_alpha(self, information_fraction: float) -> float:
        """Calculate cumulative Type I error to information fraction

        Args:
            information_fraction: information ratio (0-1)

        Returns:
            Cumulative alpha level"""
        if information_fraction <= 0:
            return 0
        if information_fraction >= 1:
            return self.alpha

        if self.spending_type == SpendingFunction.OBRIEN_FLEMING:
            # O'Brien-Fleming pattern: conservative early boundary
            return self.alpha * (2 * (1 - stats.norm.cdf(
                stats.norm.ppf(1 - self.alpha/2) / math.sqrt(information_fraction)
            )))

        elif self.spending_type == SpendingFunction.POCOCK:
            # Pocock type: more aggressive early boundary
            z_pocock = stats.norm.ppf(1 - self.alpha / 2)
            return self.alpha * math.log(1 + (math.e - 1) * information_fraction)

        elif self.spending_type == SpendingFunction.POWER_FAMILY:
            # Power family: ρ=3 (moderately conservative)
            rho = 3
            return self.alpha * (information_fraction ** rho)

        else:
            return self.alpha * information_fraction

    def boundary_z(self, information_fraction: float) -> float:
        """Calculate boundary Z value"""
        cum_alpha = self.cumulative_alpha(information_fraction)
        return stats.norm.ppf(1 - cum_alpha / 2)


class ConditionalPowerCalculator:
    """Conditional power calculator"""

    @staticmethod
    def calculate_conditional_power(
        current_z: float,
        current_n: int,
        planned_n: int,
        target_effect: float,
        pooled_std: float
    ) -> float:
        """Calculate conditional power

        Args:
            current_z: current Z statistic
            current_n: current sample size
            planned_n: planned total sample size
            target_effect: target effect size
            pooled_std: Pooled standard deviation

        Returns:
            Conditional power (0-1)"""
        if planned_n <= current_n:
            return 1.0 if current_z > stats.norm.ppf(0.975) else 0.0

        # proportion of remaining sample information
        remaining_info = 1 - current_n / planned_n

        # Expected value of final Z statistic
        delta = target_effect / (pooled_std * math.sqrt(2/planned_n))
        expected_final_z = current_z * math.sqrt(current_n / planned_n) + \
                          delta * math.sqrt(remaining_info * planned_n / 2)

        # Conditional power
        z_alpha = stats.norm.ppf(0.975)
        cp = 1 - stats.norm.cdf((z_alpha - expected_final_z) / math.sqrt(remaining_info))

        return max(0, min(1, cp))

    @staticmethod
    def calculate_new_sample_size(
        current_z: float,
        current_n: int,
        target_cp: float,
        target_effect: float,
        pooled_std: float,
        max_n: int
    ) -> int:
        """Calculate new sample size to achieve target conditional power

        Args:
            current_z: current Z statistic
            current_n: current sample size
            target_cp: target condition power
            target_effect: target effect size
            pooled_std: Pooled standard deviation
            max_n: Maximum allowed sample size

        Returns:
            new total sample size"""
        if current_z <= 0:
            # If the current trend is unfavorable, it is not recommended to increase the sample size
            return current_n

        z_alpha = stats.norm.ppf(0.975)
        z_beta = stats.norm.ppf(target_cp)

        # Backwards the required sample size based on the conditional power formula
        se = pooled_std * math.sqrt(2)
        n_new = ((z_alpha + z_beta) * se / target_effect) ** 2

        # Make sure to be at least the current sample size
        n_new = max(current_n, int(np.ceil(n_new)))

        # Do not exceed maximum sample size
        return min(n_new, max_n)


class AdaptiveTrialSimulator:
    """Adaptive clinical trial simulator"""

    def __init__(self, config: TrialConfig):
        self.config = config
        self.spending_func = AlphaSpendingFunction(
            config.spending_function, config.alpha
        )
        self.cp_calculator = ConditionalPowerCalculator()

    def simulate_single_trial(
        self,
        true_effect: float,
        is_null: bool = False
    ) -> TrialResult:
        """Simulate a single experiment

        Args:
            true_effect: true effect size (Cohen's d)
            is_null: whether it is a null hypothesis scenario

        Returns:
            Test results"""
        # The effect under the null hypothesis is 0
        actual_effect = 0.0 if is_null else true_effect

        # Initialize sample size
        n_per_arm = self.config.sample_size
        max_n = int(n_per_arm * self.config.max_sample_size_multiplier)

        # data storage
        control_data = []
        treatment_data = []

        interim_results = []
        stopped_early = False
        stop_reason = None

        # Generate complete data (for step-by-step revelation)
        full_control = np.random.normal(0, 1, max_n)
        full_treatment = np.random.normal(actual_effect, 1, max_n)

        # Interim analysis time points
        look_points = self._get_interim_look_points(n_per_arm)

        for look_idx, n_interim in enumerate(look_points):
            # Cumulative data
            control_data = full_control[:n_interim].tolist()
            treatment_data = full_treatment[:n_interim].tolist()

            # Calculate statistics
            mean_c = np.mean(control_data)
            mean_t = np.mean(treatment_data)
            std_c = np.std(control_data, ddof=1) if len(control_data) > 1 else 1
            std_t = np.std(treatment_data, ddof=1) if len(treatment_data) > 1 else 1

            # pooled standard deviation
            pooled_std = math.sqrt((std_c**2 + std_t**2) / 2)
            if pooled_std == 0:
                pooled_std = 1

            # Z statistic
            se = pooled_std * math.sqrt(2 / n_interim)
            z_score = (mean_t - mean_c) / se if se > 0 else 0
            p_value = 2 * (1 - stats.norm.cdf(abs(z_score)))

            # information ratio
            info_frac = n_interim / n_per_arm if n_interim <= n_per_arm else 1.0

            # Check boundaries
            boundary = self.spending_func.boundary_z(info_frac)
            futility_boundary = -boundary * 0.5  # simple invalidity bounds

            interim = InterimResult(
                look_number=look_idx + 1,
                cumulative_n=n_interim * 2,
                z_score=z_score,
                p_value=p_value,
                test_statistic=mean_t - mean_c,
                pooled_std=pooled_std
            )

            # Validity ceases
            if z_score > boundary:
                interim.stop_for_efficacy = True
                interim.continue_trial = False
                stopped_early = True
                stop_reason = "efficacy"
                interim_results.append(interim)
                break

            # invalidity stop
            if z_score < futility_boundary:
                interim.stop_for_futility = True
                interim.continue_trial = False
                stopped_early = True
                stop_reason = "futility"
                interim_results.append(interim)
                break

            # Adaptive sample size reestimate (last interim analysis only)
            if (self.config.design_type == DesignType.ADAPTIVE_REESTIMATE and
                look_idx == len(look_points) - 1 and
                not is_null):  # Revaluate only under alternative assumptions

                cp = self.cp_calculator.calculate_conditional_power(
                    z_score, n_interim, n_per_arm, actual_effect, pooled_std
                )

                # Promising zone approach
                if self.config.promising_zone_lower <= cp <= self.config.promising_zone_upper:
                    new_n = self.cp_calculator.calculate_new_sample_size(
                        z_score, n_interim, self.config.target_conditional_power,
                        actual_effect, pooled_std, max_n
                    )
                    if new_n > n_per_arm:
                        n_per_arm = new_n
                        interim.new_sample_size = new_n
                        # generate more data
                        additional_control = np.random.normal(0, 1, new_n - max_n)
                        additional_treatment = np.random.normal(actual_effect, 1, new_n - max_n)
                        full_control = np.concatenate([full_control, additional_control])
                        full_treatment = np.concatenate([full_treatment, additional_treatment])

            interim_results.append(interim)

        # Final analysis (if not stopped early)
        if not stopped_early:
            control_data = full_control[:n_per_arm].tolist()
            treatment_data = full_treatment[:n_per_arm].tolist()

            mean_c = np.mean(control_data)
            mean_t = np.mean(treatment_data)
            std_c = np.std(control_data, ddof=1) if len(control_data) > 1 else 1
            std_t = np.std(treatment_data, ddof=1) if len(treatment_data) > 1 else 1

            pooled_std = math.sqrt((std_c**2 + std_t**2) / 2)
            if pooled_std == 0:
                pooled_std = 1

            se = pooled_std * math.sqrt(2 / n_per_arm)
            z_score = (mean_t - mean_c) / se if se > 0 else 0
            p_value = 2 * (1 - stats.norm.cdf(abs(z_score)))

        # Judgment successful
        success = p_value < self.config.alpha and z_score > 0

        return TrialResult(
            success=success,
            final_n=n_per_arm * 2,
            stopped_early=stopped_early,
            stop_reason=stop_reason,
            interim_results=interim_results,
            p_value=p_value,
            z_score=z_score
        )

    def _get_interim_look_points(self, n_per_arm: int) -> List[int]:
        """Get interim analysis sample points"""
        if self.config.interim_looks == 0:
            return []

        # Interim analysis at equal intervals
        points = []
        for i in range(1, self.config.interim_looks + 1):
            frac = i / (self.config.interim_looks + 1)
            points.append(int(n_per_arm * frac))

        return points

    def run_simulations(self) -> Tuple[SimulationSummary, SimulationSummary]:
        """Run simulation

        Returns:
            (Results under the alternative hypothesis, results under the null hypothesis)"""
        print(f"Running {self.config.n_simulations} simulations per scenario...")

        # Simulation under alternative hypothesis (estimated Power)
        alt_results = []
        for i in range(self.config.n_simulations):
            if i % 1000 == 0 and i > 0:
                print(f"  Alternative scenario: {i}/{self.config.n_simulations}")
            result = self.simulate_single_trial(
                self.config.effect_size, is_null=False
            )
            alt_results.append(result)

        # Simulation under null hypothesis (estimate Type I error)
        null_results = []
        for i in range(self.config.n_simulations):
            if i % 1000 == 0 and i > 0:
                print(f"  Null scenario: {i}/{self.config.n_simulations}")
            result = self.simulate_single_trial(
                self.config.effect_size, is_null=True
            )
            null_results.append(result)

        # Summary results
        alt_summary = self._summarize_results(alt_results)
        null_summary = self._summarize_results(null_results)

        return alt_summary, null_summary

    def _summarize_results(self, results: List[TrialResult]) -> SimulationSummary:
        """Summary simulation results"""
        n = len(results)
        successes = sum(1 for r in results if r.success)
        early_stops_efficacy = sum(1 for r in results if r.stop_reason == "efficacy")
        early_stops_futility = sum(1 for r in results if r.stop_reason == "futility")

        # Interim Analysis Stop Rate
        interim_rates = {}
        for look in range(1, self.config.interim_looks + 1):
            stop_eff = sum(1 for r in results
                          if any(ir.look_number == look and ir.stop_for_efficacy
                                 for ir in r.interim_results)) / n
            stop_fut = sum(1 for r in results
                          if any(ir.look_number == look and ir.stop_for_futility
                                 for ir in r.interim_results)) / n
            interim_rates[look] = {
                "efficacy": stop_eff,
                "futility": stop_fut,
                "continue": 1 - stop_eff - stop_fut
            }

        return SimulationSummary(
            success_rate=successes / n,
            type_i_error=successes / n if results[0].final_n > 0 else 0,  # Whether null needs to be passed in externally
            expected_sample_size=sum(r.final_n for r in results) / n,
            early_stop_rate_efficacy=early_stops_efficacy / n,
            early_stop_rate_futility=early_stops_futility / n,
            avg_power=successes / n,
            interim_stop_rates=interim_rates
        )

    def find_optimal_design(
        self,
        sample_sizes: List[int],
        effect_sizes: List[float]
    ) -> Dict:
        """Search for optimal design parameters

        Args:
            sample_sizes: list of sample sizes to be tested
            effect_sizes: list of effect sizes to be tested

        Returns:
            optimal design solution"""
        print("Searching for optimal design parameters...")

        best_design = None
        best_score = -float('inf')

        results_matrix = []

        for n in sample_sizes:
            for eff in effect_sizes:
                self.config.sample_size = n
                self.config.effect_size = eff

                alt_summary, null_summary = self.run_simulations()

                # Rating: High Power + Low Type I error + Low sample size
                power = alt_summary.avg_power
                type_i = null_summary.type_i_error
                ess = alt_summary.expected_sample_size

                # Overall rating (higher is better)
                score = power - 5 * abs(type_i - self.config.alpha) - ess / 1000

                design_result = {
                    "sample_size": n,
                    "effect_size": eff,
                    "power": power,
                    "type_i_error": type_i,
                    "expected_sample_size": ess,
                    "score": score
                }
                results_matrix.append(design_result)

                if score > best_score:
                    best_score = score
                    best_design = design_result

                print(f"  N={n}, Effect={eff:.2f}: Power={power:.3f}, "
                      f"TypeI={type_i:.3f}, ESS={ess:.1f}, Score={score:.3f}")

        return {
            "optimal": best_design,
            "all_results": results_matrix
        }


def format_results(
    config: TrialConfig,
    alt_summary: SimulationSummary,
    null_summary: SimulationSummary
) -> Dict:
    """Format output results"""

    # Fix Type I error (from null simulation)
    null_summary.type_i_error = null_summary.avg_power

    return {
        "design_config": {
            "design_type": config.design_type.value,
            "sample_size_per_arm": config.sample_size,
            "effect_size": config.effect_size,
            "alpha": config.alpha,
            "target_power": config.power,
            "interim_looks": config.interim_looks,
            "spending_function": config.spending_function.value,
            "reestimate_method": config.reestimate_method.value,
            "n_simulations": config.n_simulations
        },
        "simulation_results": {
            "overall_success_rate": round(alt_summary.avg_power, 4),
            "type_i_error": round(null_summary.avg_power, 4),
            "power": round(alt_summary.avg_power, 4),
            "expected_sample_size": round(alt_summary.expected_sample_size, 2),
            "early_stop_rate": {
                "efficacy": round(alt_summary.early_stop_rate_efficacy, 4),
                "futility": round(alt_summary.early_stop_rate_futility, 4)
            }
        },
        "interim_analysis": {
            f"look_{k}": {
                "stop_efficacy": round(v["efficacy"], 4),
                "stop_futility": round(v["futility"], 4),
                "continue": round(v["continue"], 4)
            }
            for k, v in alt_summary.interim_stop_rates.items()
        },
        "optimal_design": {
            "recommended_n_per_arm": config.sample_size,
            "expected_power": round(alt_summary.avg_power, 4),
            "max_sample_size": int(config.sample_size * config.max_sample_size_multiplier)
        }
    }


def parse_args():
    """Parse command line parameters"""
    parser = argparse.ArgumentParser(
        description="Adaptive Trial Simulator - Adaptive Clinical Trial Simulator"
    )

    parser.add_argument(
        "--design",
        type=str,
        default="group_sequential",
        choices=["group_sequential", "adaptive_reestimate", "drop_the_loser"],
        help="Experimental design type"
    )
    parser.add_argument(
        "--n-simulations",
        type=int,
        default=10000,
        help="Simulation times"
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=200,
        help="Initial sample size per arm"
    )
    parser.add_argument(
        "--effect-size",
        type=float,
        default=0.3,
        help="True effect size (Cohen's d)"
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Overall Type I error rate"
    )
    parser.add_argument(
        "--power",
        type=float,
        default=0.80,
        help="target test effectiveness"
    )
    parser.add_argument(
        "--interim-looks",
        type=int,
        default=1,
        help="Number of interim analyzes"
    )
    parser.add_argument(
        "--spending-function",
        type=str,
        default="obrien_fleming",
        choices=["obrien_fleming", "pocock", "power_family"],
        help="Alpha consumption function"
    )
    parser.add_argument(
        "--reestimate-method",
        type=str,
        default="promising_zone",
        choices=["promising_zone", "conditional_power", "inverse_normal"],
        help="Sample size re-estimation method"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="results.json",
        help="Output file path"
    )
    parser.add_argument(
        "--visualize",
        action="store_true",
        help="Generate visualization charts"
    )
    parser.add_argument(
        "--optimize",
        action="store_true",
        help="Search for optimal design parameters"
    )

    return parser.parse_args()


def main():
    """main function"""
    args = parse_args()

    # Build configuration
    config = TrialConfig(
        design_type=DesignType(args.design),
        n_simulations=args.n_simulations,
        sample_size=args.sample_size,
        effect_size=args.effect_size,
        alpha=args.alpha,
        power=args.power,
        interim_looks=args.interim_looks,
        spending_function=SpendingFunction(args.spending_function),
        reestimate_method=ReestimateMethod(args.reestimate_method)
    )

    # Create emulator
    simulator = AdaptiveTrialSimulator(config)

    if args.optimize:
        # Search for optimal design
        sample_sizes = [100, 150, 200, 250, 300, 350, 400]
        effect_sizes = [0.2, 0.25, 0.3, 0.35, 0.4]

        optimal = simulator.find_optimal_design(sample_sizes, effect_sizes)

        output = {
            "optimization_mode": True,
            "optimal_design": optimal["optimal"],
            "parameter_sweep": optimal["all_results"]
        }

        # Restore original configuration and rerun detailed simulation
        config.sample_size = optimal["optimal"]["sample_size"]
        simulator = AdaptiveTrialSimulator(config)
        alt_summary, null_summary = simulator.run_simulations()

        output["detailed_simulation"] = format_results(config, alt_summary, null_summary)

    else:
        # Standard simulation
        alt_summary, null_summary = simulator.run_simulations()
        output = format_results(config, alt_summary, null_summary)

    # Save results
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\nResults saved to: {args.output}")
    print("\n=== Simulation Summary ===")
    print(f"Design Type: {config.design_type.value}")
    print(f"Sample Size (per arm): {config.sample_size}")
    print(f"Effect Size (Cohen's d): {config.effect_size}")
    print(f"Alpha: {config.alpha}")
    print(f"\n--- Results ---")
    print(f"Power: {alt_summary.avg_power:.4f}")
    print(f"Type I Error: {null_summary.avg_power:.4f}")
    print(f"Expected Sample Size: {alt_summary.expected_sample_size:.1f}")
    print(f"Early Stop (Efficacy): {alt_summary.early_stop_rate_efficacy:.4f}")
    print(f"Early Stop (Futility): {alt_summary.early_stop_rate_futility:.4f}")

    # Visualization
    if args.visualize:
        try:
            import matplotlib.pyplot as plt

            fig, axes = plt.subplots(2, 2, figsize=(12, 10))

            # 1. Relationship between success rate and sample size
            ax1 = axes[0, 0]
            sample_range = range(50, 500, 25)
            powers = []
            for n in sample_range:
                config.sample_size = n
                sim = AdaptiveTrialSimulator(config)
                alt, null = sim.run_simulations()
                powers.append(alt.avg_power)
            ax1.plot(sample_range, powers, 'b-', linewidth=2)
            ax1.axhline(y=config.power, color='r', linestyle='--', label=f'Target Power ({config.power})')
            ax1.set_xlabel('Sample Size per Arm')
            ax1.set_ylabel('Power')
            ax1.set_title('Power vs Sample Size')
            ax1.legend()
            ax1.grid(True, alpha=0.3)

            # 2. Interim analysis stop rate
            ax2 = axes[0, 1]
            labels = ['Efficacy', 'Futility', 'Continue']
            sizes = [
                alt_summary.early_stop_rate_efficacy,
                alt_summary.early_stop_rate_futility,
                1 - alt_summary.early_stop_rate_efficacy - alt_summary.early_stop_rate_futility
            ]
            colors = ['#2ecc71', '#e74c3c', '#3498db']
            ax2.pie(sizes, labels=labels, colors=colors, autopct='%1.1f%%', startangle=90)
            ax2.set_title('Early Stopping Distribution')

            # 3. Z-score distribution
            ax3 = axes[1, 0]
            ax3.hist([r.z_score for r in alt_summary.interim_stop_rates.values()],
                    bins=30, alpha=0.7, color='blue', edgecolor='black')
            ax3.axvline(x=stats.norm.ppf(0.975), color='r', linestyle='--', label='Significance Boundary')
            ax3.set_xlabel('Z Score')
            ax3.set_ylabel('Frequency')
            ax3.set_title('Distribution of Z Scores')
            ax3.legend()

            # 4. Infographics
            ax4 = axes[1, 1]
            info_fracs = np.linspace(0, 1, 100)
            boundaries = [simulator.spending_func.boundary_z(f) for f in info_fracs]
            ax4.plot(info_fracs, boundaries, 'g-', linewidth=2, label='Efficacy Boundary')
            ax4.plot(info_fracs, [-b for b in boundaries], 'r-', linewidth=2, label='Futility Boundary')
            ax4.fill_between(info_fracs, boundaries, 5, alpha=0.2, color='green')
            ax4.fill_between(info_fracs, -5, [-b for b in boundaries], alpha=0.2, color='red')
            ax4.set_xlabel('Information Fraction')
            ax4.set_ylabel('Z Score Boundary')
            ax4.set_title('Group Sequential Boundaries')
            ax4.legend()
            ax4.grid(True, alpha=0.3)
            ax4.set_ylim(-5, 5)

            plt.tight_layout()
            viz_file = args.output.replace('.json', '_visualization.png')
            plt.savefig(viz_file, dpi=150, bbox_inches='tight')
            print(f"\nVisualization saved to: {viz_file}")
            plt.close()

        except ImportError:
            print("\nNote: matplotlib not installed. Visualization skipped.")
            print("Install with: pip install matplotlib")


if __name__ == "__main__":
    main()
