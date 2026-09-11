project_root <- getOption("batch.skill.root", default = normalizePath(file.path(getwd(), "..", "..")))

source(file.path(project_root, "scripts", "utils.R"))
source(file.path(project_root, "scripts", "input_functions.R"))
source(file.path(project_root, "scripts", "functions.R"))
source(file.path(project_root, "scripts", "plotting.R"))
source(file.path(project_root, "scripts", "output_utils.R"))
source(file.path(project_root, "scripts", "run_analysis.R"))
