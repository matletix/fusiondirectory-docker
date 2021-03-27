# fusiondirectory-docker

Automate the build of FusionDirectory/OpenLDAP from the sources with docker.
Based on the instructions given here : https://book.gallaksys.fr/books/fusiondirectory-in-a-nutshell

## Installation

```
git clone git@github.com:matletix/fusiondirectory-docker.git
cd fusiondirectory-docker/
docker-compose up --build
```

You can then navigate to `http://localhost` to access the FusionDirectory interface.

To execute commands inside the docker container, you can run the following command while inside the `fusiondirectory-docker/` folder:
```
docker-compose exec fusiondirectory bash
```
