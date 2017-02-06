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
        let contents = try NSString(contentsOfFile: path,
                                    encoding: String.Encoding.ascii.rawValue)
        let lines:[String] = contents.components(separatedBy: "\r")
        
        //       print(lines)
        return lines
    } catch {
        print("Unable to read file: \(path)");
        return [String]() }
}


// variable initialization
var days = 0
var head = 0
var so2 = [Double]()
var co2 = [Double]()
var nox = [Double]()
var so2x = [Double]()
var co2x = [Double]()
var noxx = [Double]()
var power = [Double]()
var run = true
var noxline = 0.0
var co2line = 0.0
var so2line = 0.0

// menu for user selection
func menu() -> String
{
    print("Operation           Option")
    print("Process solar monthly file 1")
    print("Linear regressions         2")
    print("Statistical analysis       3")
    print("Estimate savings           4")
    print("Quit                       0")
    print("Enter Option: ", terminator: "")
    return strinput()
}

// loading solar csv file
func loadFile()
{
// resetting arrays
so2 = []
co2 = []
nox = []
so2x = []
co2x = []
noxx = []
power = []
    
// splits csv array into single line
func singleLine(_ linenum: Int,_  rowArray:[String])->[String]
{
    var linerow: [String]
    linerow = rowArray[linenum].components(separatedBy: ",")
    return linerow
} // end of singleLine

// relative home directory
var home = String(describing: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).replacingOccurrences(of: "file://", with: "", options: .literal, range: nil).replacingOccurrences(of: "/Documents", with: "", options: .literal, range: nil)
home.remove(at: home.index(before: home.endIndex))

// user input
print("Where is the file? ( ~ for \(home))")
let dir = strinput().replacingOccurrences(of: "~", with: home, options: .literal, range: nil)
print("How many days?")
days = (strinput() as NSString).integerValue
print("How many headers?")
head = (strinput() as NSString).integerValue

// file input
let file = readfile(dir)
for i in head...days
{
    power.append(Double(singleLine(i, file)[2])!)
    nox.append(Double(singleLine(i, file)[3])!)
    co2.append(Double(singleLine(i, file)[4])!)
    so2.append(Double(singleLine(i, file)[5])!)
}
// sets default x values
noxx = power
co2x = power
so2x = power
print("Include outliers? (0 for no, 1 for yes)")
if strinput() == "0"
{
    // purges outliers, changes x and y
    let noxnew = outliers(nox, power)[1] // temp variable
    noxx = outliers(nox, power)[0]
    nox = noxnew
    let co2new = outliers(co2, power)[1]
    co2x = outliers(co2, power)[0]
    co2 = co2new
    let so2new = outliers(so2, power)[1]
    so2x = outliers(so2, power)[0]
    so2 = so2new
}
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
    let iqr = q3 - q1 // finds inter-quartile range
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
    return [refx, ref, [Double(num)], outs]
}

func switcher(_ pre: Int) { // switch case statements
    var sel = "0"
    if pre != 0
    {
        sel = String(pre)
    }
    else
    {
        sel = menu()
    }
    switch sel {
    case "0":
        run = false
    case "1":
        loadFile()
    case "2":
        if so2.count == 0 {print("Please load file first . . ."); return}
        noxline = linReg(noxx, nox)
        co2line = linReg(co2x, co2)
        so2line = linReg(so2x, so2)
        print("NOX is y = \(noxline)x + \(yInt(noxx, nox)) ")
        print("CO2 is y = \(co2line)x + \(yInt(co2x, co2)) ")
        print("SO2 is y = \(so2line)x + \(yInt(so2x, so2)) ")
        wait()
    case "3":
        if so2.count == 0 {print("Please load file first . . ."); return}
        stat(power, "Power")
        stat(so2, "SO2")
        stat(nox, "NOX")
        stat(co2, "CO2")
        wait()
    case "4":
        if so2line == 0 {print("Please run linear regression first . . ."); return}
        print("Enter roof area and indicate units of measurement (m or ft).")
        let area = strinput()
        var panels = 0
        if area.characters.last! == "m"
        {
            panels = Int(floor(Double((area as NSString).integerValue) / 6.096))
        }
        if area.characters.last! == "t"
        {
            panels = Int(floor(Double((area as NSString).integerValue) / 30.0))
        }
        if (area.characters.last! != "m") && (area.characters.last! != "t")
        {
        print("Invalid input . . .")
        switcher(4)
        return
        }
        let powe = Double(panels) * 0.300 * 6.87671232877
        let SO2e = round((so2line * powe) * 1000) / 1000
        let NOXe = round((noxline * powe) * 1000) / 1000
        let CO2e = round((co2line  * powe) * 1000) / 1000
        let mon = powe * 0.101
        print("\(panels) panels on a \(area) ^ 2 roof generate \(round(powe * 1000)/1000) kWh a day, \(round((powe * 365.25) * 1000)/1000) kWh a year.")
        print("Estimated savings are:")
        print("\(SO2e) lbs of SO2/day, \(round((SO2e * 365.25)*1000)/1000) lbs/year;")
        print("\(NOXe) lbs of NOX/day, \(round((NOXe * 365.25)*1000)/1000) lbs/year;")
        print("\(CO2e) lbs of Co2/day, \(round((CO2e * 365.25)*1000)/1000) lbs/year;")
        print("and \(round(mon*100)/100) USD/day, \(round((mon * 365.25)*100)/100) USD/year.")
        print("These are favorable estimates for Knoxville, TN. (6.87 hours of sunlight a day, 300 watts/panel)")
        wait()
    default:
        print("Please enter a valid selection . . .")
    }
}

func wait()
{
    print("Press enter to continue . . .")
    readLine()
}

while run == true
{
    switcher(0)
}
