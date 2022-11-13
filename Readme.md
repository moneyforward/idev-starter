# How to use Idev-starter
## Install dependencies
Create bash file in project
```idev.sh
#!/usr/bin/env bash

install() {
  curl -s https://raw.githubusercontent.com/moneyforward/idev-starter/main/idev_install_dependency_script.sh > idev-starter.sh
  bash idev-starter.sh
  rm idev-starter.sh
}
```

## Add login idev script
Add login script to bash file
```idev.sh
#!/usr/bin/env bash
...

init() {
  curl -s https://raw.githubusercontent.com/moneyforward/idev-starter/main/idev_login_script.sh | bash
}
```
