#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi
starttime=$(date +%s)

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo



# //////////////////////////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////
# ////////////////////以下代码可以注释掉，第一次进行区块链的初始化///////////////
# //////////////////////////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////
# echo
# echo "POST request Create channel  ..."
# echo
# curl -s -X POST \
#   http://localhost:4000/channels \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json" \
#   -d '{
# 	"channelName":"mychannel",
# 	"channelConfigPath":"../artifacts/channel/mychannel.tx"
# }'
# echo


# echo
# sleep 5
# echo "POST request Join channel on Org1"
# echo
# curl -s -X POST \
#   http://localhost:4000/channels/mychannel/peers \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json" \
#   -d '{
# 	"peers": ["peer1","peer2"]
# }'
# echo
# echo

# echo "POST request Join channel on Org2"
# echo
# curl -s -X POST \
#   http://localhost:4000/channels/mychannel/peers \
#   -H "authorization: Bearer $ORG2_TOKEN" \
#   -H "content-type: application/json" \
#   -d '{
# 	"peers": ["peer1","peer2"]
# }'
# echo
# echo

########################################## 
########################################## 
########################################## 
####以下升级版本才需要调用（重新安装代码和初始化）
########################################## 
########################################## 
########################################## 
########################################## 
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
  "peers": ["peer1", "peer2"],
  "chaincodeName":"xcfrank",
  "chaincodePath":"github.com/xcf_rank",
  "chaincodeVersion":"v18"
}'
echo
echo
echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
  "peers": ["peer1","peer2"],
  "chaincodeName":"xcfrank",
  "chaincodePath":"github.com/xcf_rank",
  "chaincodeVersion":"v18"
}'
echo
echo

echo "POST instantiate chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
  "chaincodeName":"xcfrank",
  "chaincodeVersion":"v18",
  "args":[]
}'
echo
echo
##########################################


##############以下设置相关数据############################
# type XcfRank struct {
#   IdentificationNum string //身份证
#   InvestNum         string //投资编号
#   Date              string //参评时间，比如2018年
#   Rank              string //排名，第1名
#   Name              string //姓名
#   Organization      string //所在机构
#   RankType          string //排名类型，0 为默认类型
#   Data              string //排名的具体数据
# }
# args 的参数格式如XcfRank定义（见xcf_rank.go）
##########################################
echo "POST invoke chaincode on peers of Org1 and Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/xcfrank \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"fcn":"set",
	"args":["421181198308223915","555","2018","5","dcl5","jsfund","0","0.23"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

echo "POST invoke chaincode on peers of Org1 and Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/xcfrank \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
  "fcn":"set",
  "args":["421181198308223916","666","2018","6","dcl6","jsfund","0","0.23"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

#####查询身份证：421181198308223915和2018年的投顾排名信息
echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/xcfrank?peer=peer1&fcn=query&args=%5b%22421181198308223915%22%2c%222018%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

###testRichQuery需要安装进行CouchDB进行字段的富查询
echo "GET all 2018 ranks By testRichQuery. query chaincode on peer1 of Org1 "
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/xcfrank?peer=peer1&fcn=testRichQuery&args=%5b%222018%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


##############以下设置及查询相关数据（排名设置及查询）############################
##### 按照args=["2018"]进行查询，查询2018年的所有排名数据
echo "GET query ranks on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/xcfrank?peer=peer1&fcn=queryRanks&args=%5b%222018%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

##### 设置2018年的所有排名数据，args第一个参数为年份，后续所有参数为参评人身份证号码
echo "POST set ranks invoke chaincode on peers of Org1 and Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/xcfrank \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
  "fcn":"setRanks",
  "args":["2018","421181198308223914","421181198308223915","421181198308223916","421181198308223917"]
}')
echo "Transacton ID is $TRX_ID"
echo

##### 按照args=["2018"]进行查询，查询2018年的所有排名数据
echo "GET query ranks on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/xcfrank?peer=peer1&fcn=queryRanks&args=%5b%222018%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo



# echo "GET query Block by blockNumber"
# echo
# curl -s -X GET \
#   "http://localhost:4000/channels/mychannel/blocks/1?peer=peer1" \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo

# echo "GET query Transaction by TransactionID"
# echo
# curl -s -X GET http://localhost:4000/channels/mychannel/transactions/$TRX_ID?peer=peer1 \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo

# ############################################################################
# ### TODO: What to pass to fetch the Block information
# ############################################################################
# #echo "GET query Block by Hash"
# #echo
# #hash=????
# #curl -s -X GET \
# #  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
# #  -H "authorization: Bearer $ORG1_TOKEN" \
# #  -H "cache-control: no-cache" \
# #  -H "content-type: application/json" \
# #  -H "x-access-token: $ORG1_TOKEN"
# #echo
# #echo

# echo "GET query ChainInfo"
# echo
# curl -s -X GET \
#   "http://localhost:4000/channels/mychannel?peer=peer1" \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo

# echo "GET query Installed chaincodes"
# echo
# curl -s -X GET \
#   "http://localhost:4000/chaincodes?peer=peer1&type=installed" \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo

# echo "GET query Instantiated chaincodes"
# echo
# curl -s -X GET \
#   "http://localhost:4000/chaincodes?peer=peer1&type=instantiated" \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo

# echo "GET query Channels"
# echo
# curl -s -X GET \
#   "http://localhost:4000/channels?peer=peer1" \
#   -H "authorization: Bearer $ORG1_TOKEN" \
#   -H "content-type: application/json"
# echo
# echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
