#!/bin/bash

FILES_DIR="/home/ec2-user/files"
NGINX_HOME="/etc/nginx"
NGINX_CONF="/etc/nginx/sites-enabled"

if [ -z "$ENABLE_SSL" ]; then
    ENABLE_SSL="false"
fi

setup_dependancies() {
    yum -y update
    yum -y install git curl wget
}

install_nginx() {
    mv $FILES_DIR/nginx.repo /etc/yum.repos.d/nginx.repo
    yum install -y nginx
    chkconfig nginx on
}

install_cdn_configs() {
    rm -rf $NGINX_HOME/nginx.conf
    rm -rf $NGINX_HOME/sites-enabled/*
    mkdir -p $NGINX_CONF
    cp $FILES_DIR/nginx.conf $NGINX_HOME/nginx.conf
    cp -R $FILES_DIR/sites-enabled/* $NGINX_CONF
    chown -R nginx:nginx $NGINX_CONF
}

configure_ssl() {
    if [ "$ENABLE_SSL" == "true" ]; then
        cp -R $FILES_DIR/ssl/* $NGINX_HOME/conf.d
        chown -R nginx:nginx $NGINX_CONF
    else
        rm -rf $NGINX_CONF/ssl-com.conf
    fi
}

setup_dependancies
install_nginx
install_cdn_configs
configure_ssl
