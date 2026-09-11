project_root <- getOption("elastic.skill.root", default = normalizePath(file.path(getwd(), "..", ".."), mustWork = FALSE))

source(file.path(project_root, "scripts", "utils.R"))
source(file.path(project_root, "scripts", "validation.R"))
source(file.path(project_root, "scripts", "io.R"))
source(file.path(project_root, "scripts", "functions.R"))
source(file.path(project_root, "scripts", "modeling.R"))
source(file.path(project_root, "scripts", "output.R"))
source(file.path(project_root, "scripts", "run_analysis.R"))
