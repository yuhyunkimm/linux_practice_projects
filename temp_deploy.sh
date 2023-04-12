#!/bin/bash

echo "기존 crontab을 삭제합니다."
touch crontab_delete
crontab crontab_delete
rm crontab_delete

echo $(date)

projects_dir="/home/ubuntu/projects"

project_name="mybatis_project"
project_repo="https://github.com/jaybon1/${project_name}.git"

# 폴더가 없으면 git clone
if [[ ! -d ${projects_dir}/${project_name}/ ]]; then
    echo "${project_name}을 클론합니다."
    git clone ${project_repo} ${projects_dir}/${project_name}/
fi

echo "프로젝트 폴더로 이동합니다."
cd ${projects_dir}/${project_name}/

if [[ ! -f version.txt ]]; then
    echo "version.txt 파일을 생성합니다."
    touch version.txt
fi

git -c core.fileMode=false pull origin master
chmod 777 ./gradlew

# 버전이 같으면?
prev_version=$(cat version.txt)
now_version=$(git rev-parse master)

if [[ $prev_version == $now_version ]]; then
    echo "이전 버전과 현재 버전이 동일합니다."
    is_version_equals=true
else
    echo "이전 버전과 현재 버전이 다릅니다."
    is_version_equals=false
fi

# 프로세스가 켜져 있으면?
if pgrep -f ${project_name}.*\.jar >/dev/null; then
    echo "프로세스가 켜져 있습니다."
    is_process_on=true
else
    echo "프로세스가 꺼져 있습니다."
    is_process_on=false
fi

if [[ $is_version_equals == true && $is_process_on == true ]]; then
    echo "최신 버전 배포 상태입니다. 스크립트를 종료합니다."
else
    if [[ $is_process_on == true ]]; then
        echo "이전 프로세스를 중지합니다."
        pid=$(pgrep -f ${project_name}.*\.jar)
        kill -9 $pid
    fi

    echo "프로젝트를 빌드합니다."
    ./gradlew clean bootJar

    echo "./build/libs로 이동합니다."
    cd ./build/libs

    echo "프로젝트를 배포합니다."
    nohup java -jar *SNAPSHOT.jar 1>log.out 2>err.out &

    echo "프로젝트 폴더로 돌아옵니다."
    cd ..
    cd ..

    echo "현재 버전을 version.txt에 입력합니다."
    echo ${now_version} >version.txt
fi

if [[ "${1}_true" == "cron_true" ]]; then
    echo "cron을 재설정 합니다."
    touch crontab_new
    echo -e "* * * * * sudo ${projects_dir}/temp_deploy.sh cron" >>crontab_new
    crontab crontab_new
    rm crontab_new
else
    echo "cron을 재설정하지 않습니다."
fi
