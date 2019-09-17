/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	// "bytes"
	// "encoding/binary"
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	// "strconv"
)

var logger = shim.NewLogger("XcfRankDemo")

// XcfRankChaincode example simple Chaincode implementation
type XcfRankChaincode struct {
}

type XcfRank struct {
	IdentificationNum string //身份证
	InvestNum         string //投资编号
	Date              string //参评时间，比如2018年
	Rank              string //排名，第1名
	Name              string //姓名
	Organization      string //所在机构
	RankType          string //排名类型，0 为默认类型
	Data              string //排名的具体数据
}

func (t *XcfRankChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### XcfRankDemo Init ###########")
	// _, args := stub.GetFunctionAndParameters()
	return shim.Success(nil)
}

// Transaction makes payment of X units from A to B
func (t *XcfRankChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### XcfRankDemo Invoke ###########")

	function, args := stub.GetFunctionAndParameters()

	if function == "delete" {
		// Deletes an entity from its state
		return t.delete(stub, args)
	}

	if function == "query" {
		// queries an entity state
		return t.query(stub, args)
	}
	//testRichQuery需要安装进行CouchDB进行字段的富查询
	if function == "testRichQuery" {
		// queries an entity state
		return t.testRichQuery(stub, args)
	}

	if function == "set" {
		// Deletes an entity from its state
		return t.set(stub, args)
	}

	//分别进行排名查询和设置
	if function == "setRanks" {
		// Deletes an entity from its state
		return t.setRanks(stub, args)
	}
	if function == "queryRanks" {
		// Deletes an entity from its state
		return t.queryRanks(stub, args)
	}

	logger.Errorf("Unknown action, check the first argument, must be one of 'delete', 'query', or 'set'. But got: %v", args[0])
	return shim.Error(fmt.Sprintf("Unknown action, check the first argument, must be one of 'delete', 'query', or 'set'. But got: %v", args[0]))
}

func (t *XcfRankChaincode) setRanks(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// must be an invoke
	if len(args) <= 1 {
		return shim.Error("Incorrect number of arguments. Expecting 8, function followed by IdentificationNum,InvestNum,Date,Rank")
	}

	var Date string
	var list []string
	for key, value := range args {
		if key == 0 {
			Date = value
		} else {
			list = append(list, value)
		}
	}
	fmt.Println("rankType %s", Date)
	fmt.Println(list)
	jsonBytes, err2 := json.Marshal(list) //Json序列号
	if err2 != nil {
		fmt.Printf("%s\n", err2)
	}
	fmt.Println("rank List%s", string(jsonBytes))
	// Get the state from the ledger
	// TODO: will be nice to have a GetAllState call to ledger
	key := "XcfRankList_date:" + Date //Key格式为 Student:{Id}

	// Write the state back to the ledger
	err := stub.PutState(key, jsonBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Query callback representing the query of a chaincode
func (t *XcfRankChaincode) queryRanks(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting date")
	}
	var Date string // Entities
	var nerr error

	Date = args[0]
	// Rank = args[3]
	if Date == "" {
		return shim.Error(nerr.Error())
	}
	A := "XcfRankList_date:" + Date //Key格式为 Student:{Id}

	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(Avalbytes)
}

func (t *XcfRankChaincode) set(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// must be an invoke
	if len(args) <= 3 {
		return shim.Error("Incorrect number of arguments. Expecting 8, function followed by IdentificationNum,InvestNum,Date,Rank")
	}
	var IdentificationNum, InvestNum, Date, Rank string // Entities
	var Name, Organization, RankType, Data string       // Entities
	var err error

	IdentificationNum = args[0]
	InvestNum = args[1]
	Date = args[2]
	Rank = args[3]

	Name = args[4]
	Organization = args[5]
	RankType = args[6]
	Data = args[7]

	if IdentificationNum == "" || InvestNum == "" || Date == "" || Rank == "" {
		return shim.Error(err.Error())
	}
	// Rank = args[4]
	// Data = args[5]

	var rank = XcfRank{IdentificationNum, InvestNum, Date, Rank, Name, Organization, RankType, Data}

	// Get the state from the ledger
	// TODO: will be nice to have a GetAllState call to ledger
	key := "XcfRank:" + IdentificationNum + " date:" + Date
	studentJsonBytes, err := json.Marshal(rank) //Json序列号
	if err != nil {
		return shim.Error(err.Error())
	}

	// Write the state back to the ledger
	err = stub.PutState(key, studentJsonBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Deletes an entity from state
func (t *XcfRankChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}
	var IdentificationNum, Date string // Entities
	var err error
	IdentificationNum = args[0]
	// InvestNum = args[1]
	Date = args[1]
	// Rank = args[3]
	if IdentificationNum == "" || Date == "" {
		return shim.Error(err.Error())
	}
	key := "XcfRank:" + IdentificationNum + " date:" + Date //Key格式为 Student:{Id}

	// Delete the key from the state in ledger
	err = stub.DelState(key)
	if err != nil {
		return shim.Error("Failed to delete state")
	}

	return shim.Success(nil)
}

// Query callback representing the query of a chaincode
func (t *XcfRankChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}
	var IdentificationNum, Date string // Entities
	var nerr error

	IdentificationNum = args[0]
	// InvestNum = args[1]
	Date = args[1]
	// Rank = args[3]
	if IdentificationNum == "" || Date == "" {
		return shim.Error(nerr.Error())
	}
	A := "XcfRank:" + IdentificationNum + " date:" + Date //Key格式为 Student:{Id}

	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(Avalbytes)
}

// 以下需要安装进行CouchDB进行字段的富查询
// func getListResult(resultsIterator shim.StateQueryIteratorInterface) ([]byte, error) {
// 	defer resultsIterator.Close()
// 	// buffer is a JSON array containing QueryRecords
// 	var buffer bytes.Buffer
// 	buffer.WriteString("[")

// 	bArrayMemberAlreadyWritten := false
// 	for resultsIterator.HasNext() {
// 		queryResponse, err := resultsIterator.Next()
// 		if err != nil {
// 			return nil, err
// 		}
// 		// Add a comma before array members, suppress it for the first array member
// 		if bArrayMemberAlreadyWritten == true {
// 			buffer.WriteString(",")
// 		}
// 		buffer.WriteString("{\"Key\":")
// 		buffer.WriteString("\"")
// 		buffer.WriteString(queryResponse.Key)
// 		buffer.WriteString("\"")

// 		buffer.WriteString(", \"Record\":")
// 		// Record is a JSON object, so we write as-is
// 		buffer.WriteString(string(queryResponse.Value))
// 		buffer.WriteString("}")
// 		bArrayMemberAlreadyWritten = true
// 	}
// 	buffer.WriteString("]")
// 	fmt.Printf("queryResult:\n%s\n", buffer.String())
// 	return buffer.Bytes(), nil
// }

func (t *XcfRankChaincode) testRichQuery(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// 以下需要安装进行CouchDB进行字段的富查询
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting date")
	}
	// var Date string // Entities
	// Date = args[0]

	// queryString := fmt.Sprintf("{\"selector\":{\"Date\":\"%s\"}}", Date)
	// resultsIterator, err := stub.GetQueryResult(queryString) //必须是CouchDB才行
	// if err != nil {
	// 	return shim.Error("Rich query failed")
	// }
	// return shim.Success(resultsIterator)
	// ranks, err := getListResult(resultsIterator)
	// if err != nil {
	// 	return shim.Error("Rich query failed")
	// }
	return shim.Success(nil)
}

func main() {
	err := shim.Start(new(XcfRankChaincode))
	if err != nil {
		logger.Errorf("Error starting Simple chaincode: %s", err)
	}
}
