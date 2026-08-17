project_root <- getOption("lasso.skill.root", default = normalizePath(file.path(getwd(), "..", "..")))

source(file.path(project_root, "scripts", "utils.R"))
source(file.path(project_root, "scripts", "runtime_utils.R"))
source(file.path(project_root, "scripts", "io.R"))
source(file.path(project_root, "scripts", "modeling.R"))
source(file.path(project_root, "scripts", "plotting.R"))
source(file.path(project_root, "scripts", "run_analysis.R"))
