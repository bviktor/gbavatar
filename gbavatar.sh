#!/bin/sh

set -Ee

########################################################################
############################ START SETTINGS ############################
########################################################################

# directory where you installed gbavatar
export GBAVATAR_DIR='/opt/gbavatar'
# your netscape formatted cookie for the site you download the avatars from
# for firefox you can use https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/
export COOKIE="${GBAVATAR_DIR}/cookie.txt"
# url under which your members' pictures are hosted in user.name.jpg format
export IMAGEHOST_URL="https://portal.foobar.com/images/members"
# gitbucket's home
export GITBUCKET_DIR='/opt/gitbucket'

# server host
export DB_HOST='127.0.0.1'
# server port
export DB_PORT='5432'
# database name
export DB_NAME='gitbucket'
# database user
export DB_USER='gitbucket'
# its password
export DB_PASS='P@ssw0rd'

########################################################################
############################# END SETTINGS #############################
########################################################################

# work variables, you shouldn't change anything from this point
export DATA_DIR="${GBAVATAR_DIR}/data"
export FILE="${GBAVATAR_DIR}/users.txt"
export AVATAR_FILE='avatar.jpg'

function pg_query ()
{
    sudo -u postgres sh -c "cd && PGPASSWORD=\"${DB_PASS}\" psql --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} --username=${DB_USER} --tuples-only --no-align --field-separator=' ' --command \"${1}\""
}

# select all users who are not removed, are not groups and they're hosted in ldap meaning they don't have a password
QUERY="SELECT user_name from account WHERE removed = 'f' AND group_account = 'f' AND password = ''"
pg_query "${QUERY}" > ${FILE}

# build user list
USERS=()
test -e ${FILE} || exit
while read -r line
do
    USERS+=(${line})
done < ${FILE}

# clean up
rm -rf ${DATA_DIR}
mkdir -p ${DATA_DIR}

COUNT=${#USERS[@]}
i=0
while [ $i -lt $COUNT ]
do
    #echo ${USERS[$i]}
    AVATAR_DIR="${DATA_DIR}/${USERS[$i]}/files"

    # make sure not to stop if avatar is missing
    wget -nv --content-on-error --load-cookies=${COOKIE} "${IMAGEHOST_URL}/${USERS[$i]}.jpg" -O ${GBAVATAR_DIR}/${AVATAR_FILE} || true

    # continue if grep doesn't match, but preserve the match state anyway
    RET=1
    file ${GBAVATAR_DIR}/${AVATAR_FILE} | grep -i jpeg && RET=$? || true

    if [ ${RET} -eq 0 ]
    then
        mkdir -p ${AVATAR_DIR}
        mv ${GBAVATAR_DIR}/${AVATAR_FILE} ${AVATAR_DIR}
    fi

    let i=i+1
done

# we only made dirs for users with pictures, so use the dir list to build the new userlist
USERS=()
for f in ${DATA_DIR}/*
do
    # if you don't use parentheses around the subshell, all elements will go into the 0th index!
    USERS+=($(awk -F "/" '{print $NF}' <<< $f))
done

# copy the files as the tomcat user, we assume you run gitbucket under tomcat
sudo -u tomcat cp -R ${DATA_DIR} ${GITBUCKET_DIR}

# update the database too
for i in "${USERS[@]}"
do
    QUERY="UPDATE account SET image = 'avatar.jpg' WHERE user_name = '${i}';"
    pg_query "${QUERY}"
done
