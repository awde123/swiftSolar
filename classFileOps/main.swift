//
//  main.swift
//  Solar File Processing
//
//  Created by Gregory Croisdale(000037286) on 1/1/17.
//  Copyright © 2016 Gregory Croisdale (000037286). All rights reserved.
//


import Foundation
import Swift


// *******************************************************************
// Function strinput returns a String which it reads from the Console
//
// *********************************************************************

func strinput() -> String {
    return String(readLine()!)
} // end of function strinput

// *********************************************************************
//
// Function intinput returns an integer which it reads from the Console
//
// *********************************************************************

func intinput() -> Int {
    return Int(readLine()!)!
} // end of function intinput

// *********************************************************************
//
// Function doubleinput returns an integer which it reads from the Console
//
// *********************************************************************

func doubleinput() -> Double {
    return Double(readLine()!)!
} // end of function doubleinput

// *********************************************************************
//
// Function readfile reads a file into a large array of strings
//          each item in the array is a line from the file
//
// *********************************************************************
func readfile(_ path:String)->[String]
{
    do {
        // Read an entire text file into an NSString.
        let contents = try NSString(contentsOfFile: path,
                                    encoding: String.Encoding.ascii.rawValue)
        let lines:[String] = contents.components(separatedBy: "\r")
        
        //       print(lines)
        return lines
    } catch {
        print("Unable to read file: \(path)");
        return [String]() }
}
// ********************************************************************
//
//  Function singleLine returns a single line from the array of lines
//  from a file.  User code will extract a field from this line to obtain
//  an actual data value
// ********************************************************************

var days = 0
var head = 0
var so2 = [Double]()
var co2 = [Double]()
var nox = [Double]()
var power = [Double]()
var run = true

func menu() -> String
{
    print("Operation           Option")
    print("Process monthly file   1")
    print("Linear regressions     2")
    print("Statistical Analysis   3")
    print("Quit                   0")
    print("Enter Option: ", terminator: "")
    return strinput()
}

func loadFile()
{
so2 = []
co2 = []
nox = []
power = []
func singleLine(_ linenum: Int,_  rowArray:[String])->[String]
{
    var linerow: [String]
    linerow = rowArray[linenum].components(separatedBy: ",")
    return linerow
} // end of singleLine
var home = String(describing: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).replacingOccurrences(of: "file://", with: "", options: .literal, range: nil).replacingOccurrences(of: "/Documents", with: "", options: .literal, range: nil)
home.remove(at: home.index(before: home.endIndex))
print("Where is the file? ( ~ for \(home))")
let dir = strinput().replacingOccurrences(of: "~", with: home, options: .literal, range: nil)
print("How many days?")
days = intinput()
print("How many headers?")
head = intinput()
let file = readfile(dir)
for i in head...days
{
    power.append(Double(singleLine(i, file)[2])!)
    nox.append(Double(singleLine(i, file)[3])!)
    co2.append(Double(singleLine(i, file)[4])!)
    so2.append(Double(singleLine(i, file)[5])!)
}
}

func dictFromArray(_ x: [Double],_ y: [Double]) -> [Double: Double]
{
    var dic: [Double: Double] = [:]
    for i in 0...x.count - 1
    {
        dic[x[i]] = y[i]
    }
    return dic
}
    
func linReg(_ a: [Double], _ b: [Double]) -> Double
{
    let comb = outliers(b, a)
    let x = comb[0]
    let y = comb[1]
    var prod = 0.0
    var squ = 0.0
    for i in 0...x.count - 1
    {
        prod += x[i] * y[i]
        squ += pow(x[i], 2)
    }
    let top = ((Double(x.count) * prod - (x.reduce(0, +) * y.reduce(0, +))))
    let bot = ((Double(x.count) * squ) - (pow(x.reduce(0, +), 2)))
    return (top / bot)
}

func yInt(_ a: [Double], _ b: [Double]) -> Double
{
    let comb = outliers(b, a)
    let x = comb[0]
    let y = comb[1]
    var prod = 0.0
    var squ = 0.0
    for i in 0...x.count - 1
    {
        prod = x[i] * y[i] + prod
        squ = pow(x[i], 2) + squ
    }
    let top = ((y.reduce(0, +) * squ) - (x.reduce(0, +) * prod))
    let bot = ((Double(x.count) * squ) - pow(x.reduce(0, +), 2))
    return (top / bot)
}

func stat(_ array: [Double], _ name: String) // various statistical calcuations
{
    var arr = array.sorted(by: <)
    var sum = 0.0
    var dev = 0.0
    let median = arr[arr.count/2]
    for i in 0...arr.count-1
    {
        sum = arr[i] + sum
    }
    let average = Double(sum) / Double(arr.count)
    for i in 0...arr.count-1
    {
        let x = Double(arr[i])
        dev = dev + (abs(x - average)/Double(arr.count))
    }
    print("\(name):, Count : \(arr.count), Sum: \(sum), Median: \(median), Average: \(average), σ: \(standardDeviation(arr: arr))")
}

func standardDeviation(arr : [Double]) -> Double
{
    let length = Double(arr.count)
    let avg = arr.reduce(0, {$0 + $1}) / length
    let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
    return sqrt(sumOfSquaredAvgDiff / length)
}

func outliers(_ array : [Double], _ xx : [Double]) -> [[Double]]
{
    var num = xx.count
    var ref = [Double]()
    var refx = [Double]()
    let dict = dictFromArray(array, xx).sorted(by: <)
    let a = dict.map { $0.0 }
    let x = dict.map { $0.1 }
    let q1 = a[a.count / 4]
    let q3 = a[3 * a.count / 4]
    let iqr = q3 - q1
    for i in 0...a.count - 1
    {
        if !(a[i] > (1.5 * iqr) + q3) && !(a[i] < q1 - (1.5 * iqr))
        {
            ref.append(a[i])
            refx.append(x[i])
            num -= 1
        }
    }
    print("x \(refx)")
    print("y \(ref)")
    print("Found \(num) outliers")
    return [refx, ref]
}


while run == true
{
    switch menu()
    {
    case "0":
        run = false
    case "1":
        loadFile()
    case "2":
        print("NOX is y = \(linReg(power, nox))x + \(yInt(power, nox)), CO2 is y = \(linReg(power, co2))x + \(yInt(power, co2)), and SO2 is y = \(linReg(power, so2))x + \(yInt(power, so2))")
    case "3":
        stat(power, "power")
        stat(so2, "SO2")
        stat(nox, "NOX")
        stat(co2, "CO2")
    default:
        print("Please enter a valid selection . . .")
    }
    
}
