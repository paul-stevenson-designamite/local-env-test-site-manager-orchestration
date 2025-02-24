# Define the branch variable that can be passed in via command line
variable "BRANCH" {
    default = "" # Empty default means use current branch
}

# Helper function that determines which branch to use
# If BRANCH is provided via command line, use that
# Otherwise, execute git command to get current branch
function "get_branch" {
    params = [path]
    result = notequal("",BRANCH) ? BRANCH : system("cd ${path} && git rev-parse --abbrev-ref HEAD")
}

# Get commit hash for tagging
function "get_commit" {
    params = [path]
    result = system("cd ${path} && git rev-parse --short HEAD")
}

# NEW UI base configuration - shared between new-ui services
target "new-ui-base" {
    context = "./site-manager-new-ui"
    dockerfile = "./docker-services/dockerfiles/apache.dockerfile"
    args = {
        APP_ENV = get_branch("./site-manager-new-ui") # Gets branch for new-ui directory 
    }
}

# NEW UI specific services
target "new-ui-server" {
    inherits = ["new-ui-base"]
    target = "server"
    tags = ["new-ui-server:${get_branch('./site-manager-new-ui')}-${get_commit('./site-manager-new-ui')}"]
}

target "new-ui-app" {
    inherits = ["new-ui-base"]
    dockerfile = "./docker-services/dockerfiles/php.dockerfile"
    tags = ["new-ui-app:${get_branch('./site-manager-new-ui')}-${get_commit('./site-manager-new-ui')}"]
}

# Legacy configuration follows the same pattern
target "legacy-base" {
    context = "./site-manager-legacy"
    dockerfile = "./docker-services/dockerfiles/apache.dockerfile"
    args = {
        APP_ENV = get_branch("./site-manager-legacy")
    }
}

target "legacy-server" {
    inherits = ["legacy-base"]
    target = "server"
    tags = ["legacy-server:${get_branch('./site-manager-legacy')}-${get_commit('./site-manager-legacy')}"]
}

target "legacy-app" {
    inherits = ["legacy-base"]
    dockerfile = "./docker-services/dockerfiles/php.dockerfile"
    tags = ["legacy-app:${get_branch('./site-manager-legacy')}-${get_commit('./site-manager-legacy')}"]
}

# API configuration follows the same pattern
target "api-base" {
    context = "./site-manager-api"
    dockerfile = "./docker-services/dockerfiles/apache.dockerfile"
    args = {
        APP_ENV = get_branch("./site-manager-api")
    }
}

target "api-server" {
    inherits = ["api-base"]
    target = "server"
    tags = ["api-server:${get_branch('./site-manager-api')}-${get_commit('./site-manager-api')}"]
}

target "api-app" {
    inherits = ["api-base"]
    dockerfile = "./docker-services/dockerfiles/php.dockerfile"
    tags = ["api-app:${get_branch('./site-manager-api')}-${get_commit('./site-manager-api')}"]
}

# Groups define collections of targets that can be built together
group "default" {
    targets = ["new-ui-server", "new-ui-app", "legacy-server", "legacy-app", "api-server", "api-app"]
}

group "new-ui" {
    targets = ["new-ui-server", "new-ui-app"]
}

group "legacy" {
    targets = ["legacy-server", "legacy-app"]
}

group "api" {
    targets = ["api-server", "api-app"]
}