# GitUI
I want to setup a personal Git server with a web GUI similar to the github.com to view files and diffs. GitHub is proprietary, and GitLab CE has too many features. It also recommended 4GB of RAM and at least a 2-core CPU. I didn't want to assign that much resource for such a simple need so I decided to do an experiment. This project will build a personal GitHub-like system with minimum functionality and system resource requirement that only meets my need.

## User Guide
For Ubuntu 16.04 LTS

Enable the port 11111 access in the UFW rule
```
sudo ufw allow 11111/tcp
sudo ufw reload
```

Update the Git Repo location
```
The default Git Repo storage location is under your home directory ~/db/gitui
This is the default set in docker-compose.yml and hardcoded into the repos_controller.rb create method.
To choose a different location, update the docker-compose.yml and the @repo[:url] variable in the create method
```

Start the GitUI Docker container
```
git clone git@github.com:tony-yang/gitui.git
cd gitui
make start
```

Start the WebUI
```
docker-compose exec gitui bash
cd ~/gitui/gitui
bundle install
rails server -p 11111 -b 0.0.0.0
```

## Dev Guide
To start the dev environment, make sure the system has Docker, Docker Compose, and Make installed. All other dependencies will be installed inside the container and ready for development.
```
git clone git@github.com:tony-yang/gitui.git
cd gitui
make start
docker-compose exec gitui bash
cd ~/gitui/gitui
bundle install
rails test
```


## TODO
- Add a way to setup and teardown test git repos in order to run proper system/integration tests
- Add system/integration tests
- Investigate coverage report
- Refactor functional code in the controller into modules/methods and move it out of the controller
- Refactor views to better reuse code snippets
- Add a catch all redirect 404 page instead of crash


## Resources
The core git library that GitLab and GitHub used for interfacing between git and the programming env
https://libgit2.github.com/
https://github.com/libgit2/rugged

Building GitHub slide I found online
https://zachholman.com/talk/how-to-build-a-github/

GitHub architecture
https://github.com/blog/530-how-we-made-github-fast

GitLab architecture overview
https://docs.gitlab.com/ce/development/architecture.html
https://about.gitlab.com/handbook/infrastructure/production-architecture/

StackOverflow article
https://stackoverflow.com/questions/4892602/how-does-the-github-website-work-architecture

Syntax highlight library
http://prismjs.com
