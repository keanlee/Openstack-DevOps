#!/usr/bin/env python
# -*- coding: utf-8 -*-

import urllib,urllib2,json
import argparse,logging
import datetime,pdb
import sys,os
reload(sys)
#sys.setdefaultencoding( "utf-8" )


class WeChat(object):

        __token_id = ''
        # init attribute
        def __init__(self,url):
                self.__url = url.rstrip('/')
                self.__corpid = 'wxd0d7b4c71e25a03d'
                self.__secret = 'JRCe0uswY2H6V_3yMP1Lm3mAPyXLRtgzilg6PPVNGLW4WhWxvAxSOZVo1HzM4tQq'
                self.__toparty = '2'
                self.__agentid = '1'


        # Get TokenID
        def authID(self):
                params = {'corpid':self.__corpid, 'corpsecret':self.__secret}
                data = urllib.urlencode(params)
                content = self.getToken(data)

                try:
                        self.__token_id = content['access_token']
                        #print content['access_token']
                except KeyError:
                        raise KeyError
        # Establish a connection
        def getToken(self,data,url_prefix='/'):
                url = self.__url + url_prefix + 'gettoken?'
                try:
                        response = urllib2.Request(url + data)
                except KeyError:
                        raise KeyError
                result = urllib2.urlopen(response)
                content = json.loads(result.read())
                return content

        # Get sendmessage url
        def postData(self,data,url_prefix='/'):
                url = self.__url + url_prefix + 'message/send?access_token=%s' % self.__token_id
                request = urllib2.Request(url,data)
                try:
                        result = urllib2.urlopen(request)
                except urllib2.HTTPError as e:
                        if hasattr(e,'reason'):
                                print 'reason',e.reason
                        elif hasattr(e,'code'):
                                print 'code',e.code
                        return 0
                else:
                        content = json.loads(result.read())
                        result.close()
                return content

        # send message
        def sendMessage(self,touser,message):
                self.authID()

                data = json.dumps({
                        'touser':touser,
                       # 'toparty':self.__toparty,
                        'msgtype':"text",
                        'agentid':self.__agentid,
                        'text':{
                                'content':message
                        },
                        'safe':"0"
                },ensure_ascii=False)

                response = self.postData(data)
                return response

        #Define Logfiel Writing Function
        def logwrite(self,status,receiver,content):

                logpath='/var/log/zabbix/alert'

                if not os.path.isdir(logpath):
                        os.makedirs(logpath)
                t=datetime.datetime.now()
                daytime=t.strftime('%Y-%m-%d')
                daylogfile=logpath+'/'+'Wechat'+str(daytime)+'.log'
                logging.basicConfig(filename=daylogfile,level=logging.DEBUG)
                logging.info('*'*50)
                logging.debug(str(t)+'{0}\nMSG sent to WechatID:\"{1}\" with CONTENT:{2}'.format(json.dumps(status),receiver,content))

if __name__ == '__main__':
        print "Wechat used!"
        parser = argparse.ArgumentParser(description='Send Wechat MSG to user from zabbix alerting')
        parser.add_argument('receiver',action="store", help='The receiver of the MSG that send to user ')
        parser.add_argument('subject',action="store", help='For occupation in Zabbix V2.*.* ')
        parser.add_argument('content',action="store", help='The content of the MSG!')
        args=parser.parse_args()
        receiver=args.receiver
        content=args.subject+"\n\n"+args.content
        a = WeChat('https://qyapi.weixin.qq.com/cgi-bin')
      #  pdb.set_trace()
        status=a.sendMessage(receiver,content)
        a.logwrite(status, receiver, content)



