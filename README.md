to generate .env run



```
cat << EOT > .env 
PROJECT=`basename "$PWD"`
USER_ID=`id -u $USER`
GROUP_ID=`id -g $USER`
USER_NAME=`id -un $USER`
GROUP_NAME=`id -gn $USER`
EOT
```
