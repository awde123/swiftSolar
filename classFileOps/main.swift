//
//  main.swift
//  Solar File Processing
//
//  Created by Gregory Croisdale(000037286) on 1/1/17.
//  Copyright © 2016 Gregory Croisdale (000037286). All rights reserved.
//


import Foundation
import Swift


// strinput returns user input str
func strinput() -> String {
    return String(readLine()!)
} // end of function strinput

// reads and separates csv into lines
func readfile(_ path:String)->[String]
{
    do {
        // Read an entire text file into an NSString.
        let contents = try NSString(contentsOfFile: path, encoding: String.Encoding.ascii.rawValue)
        let lines:[String] = contents.components(separatedBy: "\r")
        // print(lines)
        return lines
    } catch {
        print("Unable to read file: \(path)");
        return [String]() }
}


// variable initialization
var row = 0
var head = 0
var arrays = [String: [(Double, Double)]]()
var run = true
var noxline = 0.0
var co2line = 0.0
var so2line = 0.0

// menu for user selection
func menu() -> String
{
    print("Operation           Option")
    print("Process solar monthly file 1")
    print("Remove outliers            2")
    print("Linear regressions         3")
    print("Statistical analysis       4")
    print("Process weather file       5")
    print("Quit                       0")
    print("Enter Option: ", terminator: "")
    return strinput()
}

// splits csv array into single line
func singleLine(_ linenum: Int,_  rowArray:[String])->[String]
{
    var linerow: [String]
    linerow = rowArray[linenum].components(separatedBy: ",")
    return linerow
} // end of singleLine

// loading solar csv file
func loadFile(_ columns: [Int]) -> [[Double]]
{
// relative home directory
var home = String(describing: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).replacingOccurrences(of: "file://", with: "", options: .literal, range: nil).replacingOccurrences(of: "/Documents", with: "", options: .literal, range: nil)
home.remove(at: home.index(before: home.endIndex))
// user input
print("Where is the file? ( ~ for \(home))")
let dir = strinput().replacingOccurrences(of: "~", with: home, options: .literal, range: nil)
print("How many rows?")
row = (strinput() as NSString).integerValue
print("How many headers?")
head = (strinput() as NSString).integerValue

// file input
let file = readfile(dir)
var exp = [[Double]]()
exp = []
for x in 0...columns.count - 1
{
    var temp = [Double]()
    temp = []
for i in head...row
{
    temp.append(Double(singleLine(i, file)[columns[x]])!)
}
    exp.append(temp)
}
return exp
} // end of loadFile

// transforms [x] and [y] array into [x: y] dictionary
func dictFromArray(_ x: [Double],_ y: [Double]) -> [Double: Double]
{
    var dic: [Double: Double] = [:]
    for i in 0...x.count - 1
    {
        dic[x[i]] = y[i]
    }
    return dic
} // end of dictFromArray

// performs linear regression to find slope
func linReg(_ x: [Double], _ y: [Double]) -> Double
{
    var prod = 0.0
    var squ = 0.0
    for i in 0...x.count - 1
    {
        prod += x[i] * y[i]
        squ += pow(x[i], 2)
    }
    let top = ((Double(x.count) * prod - (x.reduce(0, +) * y.reduce(0, +)))) // numerator
    let bot = ((Double(x.count) * squ) - (pow(x.reduce(0, +), 2))) // denominator
    return (top / bot) // slope
} // end of linReg

// finds appropriate y-intercept
func yInt(_ x: [Double], _ y: [Double]) -> Double
{
    var prod = 0.0
    var squ = 0.0
    for i in 0...x.count - 1
    {
        prod = x[i] * y[i] + prod
        squ = pow(x[i], 2) + squ
    }
    let top = ((y.reduce(0, +) * squ) - (x.reduce(0, +) * prod)) // numerator
    let bot = ((Double(x.count) * squ) - pow(x.reduce(0, +), 2)) // denominator
    return (top / bot) // quotient
} // end of yInt

// various statistical calcuations
func stat(_ array: [Double], _ name: String)
{
    var arr = array.sorted(by: <) // sorts array (to find median)
    // variable initialization
    var sum = 0.0
    var dev = 0.0
    // calculations
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
} // end of stat

// finds standard deviation (average distance from mean squared)
func standardDeviation(arr : [Double]) -> Double
{
    let length = Double(arr.count)
    let avg = arr.reduce(0, {$0 + $1}) / length
    let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
    return sqrt(sumOfSquaredAvgDiff / length)
} // end of stdDev

// finds and eliminates outliers to ensure accruate calculations
func outliers(_ array : [Double], _ xx : [Double]) -> [[Double]]
{
    var num = xx.count
    var ref = [Double]()
    var refx = [Double]()
    var outs = [Double]()
    let dict = dictFromArray(array, xx).sorted(by: <) // creates and sorts [x: y] dictionary
    let a = dict.map { $0.0 }
    let x = dict.map { $0.1 }
    let q1 = a[a.count / 4]
    let q3 = a[3 * a.count / 4]
    let iqr = q3 - q1 // finds interquartile range
    for i in 0...a.count - 1
    {
        if !(a[i] > (1.5 * iqr) + q3) && !(a[i] < q1 - (1.5 * iqr)) // array without outliers
        {
            ref.append(a[i])
            refx.append(x[i])
            num -= 1
        }
        if (a[i] > (1.5 * iqr) + q3) || (a[i] < q1 - (1.5 * iqr)) // array of outliers
        {
            outs.append(a[i])
        }
    }
    return [refx, ref, [Double(num)], outs] // x array w/o outliers, y array w/o outliers, [number of outliers], y values of outliers
} // end of outliers

func estimation(_ pre: String) {
    var area = "0"
    if pre == "0" {print("Enter roof area and indicate units of measurement (m or ft)."); area = strinput()}
    else {area = pre}
    var panels = 0
    // determining units
    if area.characters.last! == "m" // meters
    {
        panels = Int(floor(Double((area as NSString).integerValue) / 6.096))
    }
    if area.characters.last! == "t" // feet
    {
        panels = Int(floor(Double((area as NSString).integerValue) / 30.0))
    }
    if (area.characters.last! != "m") && (area.characters.last! != "t") // invalid
    {
        print("Invalid input . . .")
        switcher(4)
        return
    }
    // calculation
    let powe = Double(panels) * 0.300 * 6.87671232877
    let SO2e = round((so2line * powe) * 1000) / 1000
    let NOXe = round((noxline * powe) * 1000) / 1000
    let CO2e = round((co2line  * powe) * 1000) / 1000
    let mon = powe * 0.101
    // output
    print("************")
    print("\(panels) panels on a \(area) ^ 2 roof generate \(round(powe * 1000)/1000) kWh a day, \(round((powe * 365.25) * 1000)/1000) kWh a year.")
    print("Estimated savings are:")
    print("\(SO2e) lbs of SO2/day, \(round((SO2e * 365.25)*1000)/1000) lbs/year;")
    print("\(NOXe) lbs of NOX/day, \(round((NOXe * 365.25)*1000)/1000) lbs/year;")
    print("\(CO2e) lbs of Co2/day, \(round((CO2e * 365.25)*1000)/1000) lbs/year;")
    print("and \(round(mon*100)/100) USD/day, \(round((mon * 365.25)*100)/100) USD/year.")
    print("These are favorable estimates for Knoxville, TN. (6.87 hours of sunlight a day, 300 watts/panel)")
    print("************")
    wait()
} // end of estimator

// switch case statements
func switcher(_ pre: Int) {
    var sel = "0"
    if pre != 0 // allows for automatic case selection
    {
        sel = String(pre)
    }
    else // otherwise, prints all options and returns user input
    {
        sel = menu()
    }
    switch sel {
    case "0": // exit
        run = false
    case "1": // loads solar file
        // resetting arrays
        arrays.removeAll()
        // generate new arrays
        let read = loadFile([2,3,4,5])
        for i in 0...read[2].count - 1
        {
            arrays["Power"]!.append((0.0, read[0][i]))
            arrays["SO2"]!.append((arrays["Power"]![i].1, read[3][i]))
            arrays["CO2"]!.append((arrays["Power"]![i].1, read[2][i]))
            arrays["SOX"]!.append((arrays["Power"]![i].1, read[1][i]))
        }
    case "2":
        print("************")
        print("Removing outliers . . .")
        print("************")
        // purges outliers, changes x and y
        for (i, v) in arrays
        {
            let ind = arrays[i]
            var xArr = [Double]()
            var yArr = [Double]()
            for k in 0...(arrays[i]!.count) - 1
            {
                xArr += arrays[i]![k].0
                yArr += arrays[i]![k].1
            }
            let new = outliers(xArr, yArr)[1] // temp variable
            arrays[i].0 = outliers(xArr, yArr)[0]
            nox = new
        }
    case "3": // linear regression
        if so2.count == 0 {print("Please load file first . . ."); return}
        noxline = linReg(noxx, nox)
        co2line = linReg(co2x, co2)
        so2line = linReg(so2x, so2)
        print("************")
        print("NOX is y = \(noxline)x + \(yInt(noxx, nox)) ")
        print("CO2 is y = \(co2line)x + \(yInt(co2x, co2)) ")
        print("SO2 is y = \(so2line)x + \(yInt(so2x, so2)) ")
        print("************")
        print("Would you like to estimate savings for Farragut High School? (y/n)")
        if strinput() == "y"
        {
            estimation("111400ft")
        }
    case "4": // statistical analysis
        if so2.count == 0 {print("Please load file first . . ."); return}
        print("************")
        stat(power, "Power")
        stat(so2, "SO2")
        stat(nox, "NOX")
        stat(co2, "CO2")
        print("************")
        wait()
    case "5": // weather regression
        let read = loadFile([10, 11, 15])
        let minT = read[1]
        let maxT = read[0]
        let wind = read[2]
        var diff = [Double]()
        diff = []
        for i in 0...minT.count - 1
        {
            diff.append(maxT[i] - minT[i])
        }
        print(linReg(diff, wind))
    default:
        print("Please enter a valid selection . . .")
    }
} // end of switcher

func wait() // requires user to press enter to continue
{
    print("Press enter to continue . . .")
    readLine()
} // end of wait

while run == true // eternally run switcher until stopped
{
    switcher(0)
} // end of program
