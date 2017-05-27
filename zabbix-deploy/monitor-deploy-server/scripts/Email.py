#!/usr/bin/python
#coding:utf-8

import smtplib
from email.mime.text import MIMEText
import os
import argparse
import logging
import datetime

#Writen for Zabbix 2.4.8 with three parameters need: receiveremail,subject,content
#mail_host = 'smtp.163.com'
#the mail_user and password need to sign up 
mail_host = 'smtp.chinatelecom.cn'
mail_host_port = 465
mail_user = 'XXX'
mail_pass = 'XXX'
mail_postfix = 'chinatelecom.cn'

def send_mail(mail_to,subject,content):
    me = mail_user+"<"+mail_user+"@"+mail_postfix+">"
    msg = MIMEText(content)
    msg['Subject'] = subject
    msg['From'] = me
    msg['to'] = mail_to
    global sendstatus
    global senderr

    try:
        smtp=smtplib.SMTP_SSL()
        smtp.connect(mail_host,mail_host_port)
        smtp.login(mail_user + "@"+mail_postfix,mail_pass)
        smtp.sendmail(me,mail_to,msg.as_string())
        smtp.close()
        print 'send ok'
        sendstatus = True
    except Exception,e:
        senderr=str(e)
        print senderr
        sendstatus = False

def logwrite(sendstatus,mail_to,subject,content):
    logpath='/var/log/zabbix/alert'

    if not sendstatus:
        content = senderr

    if not os.path.isdir(logpath):
        os.makedirs(logpath)

    t=datetime.datetime.now()
    daytime=t.strftime('%Y-%m-%d')
    daylogfile=logpath+'/'+'Email'+str(daytime)+'.log'
    logging.basicConfig(filename=daylogfile,level=logging.DEBUG)
    logging.info('*'*130)
    logging.debug(str(t)+'mail send to {0} with subject:\"{1}\", content is :\n {2}'.format(mail_to,subject,content))
if __name__ == "__main__":
    print "email used!"
    parser = argparse.ArgumentParser(description='Send mail to usr fro zabbix alerting')
    parser.add_argument('mail_to',action="store", help='The address of the E-mail that send to user ')
    parser.add_argument('subject',action="store", help='The subject of the E-mail')
    parser.add_argument('content',action="store", help='The content of the E-mail')
    args=parser.parse_args()
    mail_to=args.mail_to
    subject=args.subject
    content=args.content

    send_mail(mail_to, subject, content)
    logwrite(sendstatus, mail_to, subject, content)

