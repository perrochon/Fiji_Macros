// Copyright (c) 2024 Louis Perrochon
// This macro is provided under the MIT license.
// The MIT license in short grants anyone to do pretty much anything they want with it. 
//
// This Macro will call "Measure" on an open tif file, or a directory of tif files of the form
// 
//     date name condition FOV.tif 
//
// with an ROI set in a file of the same name (including extension) + ".ROIset.zip" and store the results
// in a CSV file.
//
// Then it will do some post processing on the file, in particular compute mean and similar numbers on various subset of the data
// It will do it based on the "condition" and also based on "con-FOV" which is for each condition and Field of View.
// The labels of the columns can easily be adjusted to other needs, of course.

version = "V1.0" // change this if you change the code

// Default values you can set before running the script - but there is a dialog asking the user
var channel = 2
var l2 = "======================================="
var l1 = l2+l2;

// Main

setBatchMode(true); 

// Clean up things
print("\\Clear");
run("Clear Results");

h1("Measure_Macro "+ version + " " + getTime());
print("FIJI/ImageJ Version:  " + IJ.getFullVersion() 
	+ " (" + getInfo("os.name") + " " + getInfo("os.version") + ")" 
	+ " (Java: " + getInfo("java.version") + ")");

// Ask for parameters for JACoP
Dialog.create("Channel to Measure");
Dialog.addNumber("Channel",channel);
Dialog.show();
channel=Dialog.getNumber();

if (nImages > 0) {
	// We have an active image. Process it
	processImage(getDirectory("image"), getTitle());
	h2("Finished Image: " + getTitle());
	outputPath = getDirectory("image")+getTitle();
} else {
	// No open image, ask for a directory
	folderPath = getDirectory("Choose a Directory");	
	processFolder(folderPath);
	outputPath = folderPath + "All-" + channel;	
}

finishUp(outputPath);

setBatchMode(false);

// turn this on for debugging paths and such
//printJavaProperties(); 

// End Main


// Functions

function processFolder(input) {
	// Call processImage on all images in a folder
	h1("Processing Directory: " + input);
	print("channel = " + channel);

	list = getFileList(input);
	list = Array.sort(list);
	count = 0;
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], "tif")){
			open(folderPath + list[i]);
			processImage(folderPath, list[i]);
			close(list[i]);
			count++;
		}
	}
	h2("Finished Directory: " + input);
	print("Images processed: " + count);
	print("ROIs processed:" + nResults);

}

function processImage(directory, image) {
	// Call JACoP on all ROI of a single image
	h1("Processing image: " + image);
	print("channel = " + channel);
	print("Path:  " + directory + image);
	
	roiManager("reset");
	
	print("ROI set: " + directory + image + ".ROIset.zip");
	roiManager("open", directory + image + ".ROIset.zip");	
	count = roiManager("count");
	print("Number of ROIs: " + count);
	
	run("Duplicate...", "duplicate channels="+channel);
	run("Set Measurements...", "area mean display redirect=None decimal=3");
	roiManager("Measure");
	
	close(); // should only close the duplicate (active) window.
	
	//print(roiManager("size") + " ROI measured");
}


function finishUp(outputPath) {
	// Post process log and finish everything up
	
	h1("Image Analysis complete, doing some math and cleaning up");
	
	// You need to turn on displaying labels of ROI in settings, so that the result table has strings of the form
	// filename:ROI name, e.g. 022924 cHeLa DMSO FOV1-1-1.tif:0003-0407-0799
	// Then you can call the following function to parse that into further rows.
	processTable();
	
	// Generate a table and then from that a CSV file by parsing the log file
	h2("Generating csv:  " +  outputPath + ".Results.Measure.csv");
	saveAs("results", outputPath +".Results.Measure.csv");

	// Attempt to copy the source code of the macro to the log file for documentation
	// If you can't get this to run, comment out the next two lines.
	h2("Attempting to append Macro to log");
	copyMacro();
	
	// we print a time stamp before saving the log so have it in the log
	h2("Macro finished at: " + getTime()); 
	
	// Saving the log file
	h2("Log saved at:  " + outputPath + ".Log.Measure.txt");
	selectWindow("Log");
	saveAs("Text", outputPath + ".Log.Measure.txt");
}

// https://wsr.imagej.net/developer/macro/functions.html#setResult
// Table.getString(columnName, rowIndex) - Returns a string value from the cell at the specified column and row.
// updateResults();

function processTable() {
// Parse the Label column in the Result Table into it's elements
// You may need to change this parse if you have a different file name convention


	for (i = 0; i < nResults; i++) {
		label = Table.getString("Label", i); // e.g. "022924 cHeLa DMSO FOV1-1-1.tif:0003-0760-1287"
		label = replace(label,":"," ");
		s = split(label); 
		// The array is 0 based, so s[0] Date
		date = s[0]; 
		experiment = s[1];
		condition = s[2];
		fov = s[3];
		fov = replace(fov,".tif",""); // this is how we remove the .tif at the end. Keep this 
		fov = replace(fov,"-1-1",""); // then we also remove the -1 for our example data
		//roiLabel = s[4];
		filename = condition + "-" + fov; // this is the filename we will put into the table
		Table.set("Date", i, date);
		Table.set("Experiment", i, experiment);
		Table.set("Condition", i, condition);
		Table.set("FOV", i, fov);
		//Table.set("ROI Label",i, roiLabel);
		Table.set("Channel", i, channel);
		Table.set("Con-FOV", i, filename);		
	}
	updateResults();	
	computeStats("Con-FOV", "Mean");
	computeStats("Condition", "Mean");
	updateResults();

}

function computeStats(group, value){
	// group, value are strings indicating column labels of the current table
	// For all rows with the same value in column group
	// 	call computeStat2, which will
	//		for column value
	//			compute mean, deviation, std, min, max, median and add to results table and log
	//			(deviation for each row is only in results table)

h2("Computing means grouped by " + group);
	Table.sort(group);
	current = "";
	first = 0;
	last = 0 ;
	for (i = 0; i < nResults; i++) {
		if (current != Table.getString(group, i)) { //we found a new condition
			if (current != "") { // finish previous condition
				computeStats2(group, current, value, first, last);
			}
			current = Table.getString(group, i);
			first = i;
			last = i;
		} else {
			last = i;
		}
	}		
	computeStats2(group, current, value, first, last);	
}

function computeStats2(group, current, value, first, last) {
	// group, value are strings indicating column labels of the current table
	// current is the current value for the group
	// first, last are rows
	// For rows from first to last (including both)
	//	for column value
	//		compute mean, deviation, std, min, max, median and add to results table and log
	//		(deviation for each row is only in results table)

	values = Table.getColumn(value);
	values = Array.slice(values, first, last+1);
	Array.getStatistics(values, min, max, mean, std);

	// median
	values = Array.sort(values);
	median = 0;
	if (values.length % 2 > 0.5) {
		median = values[floor(values.length / 2)];
	} else {
		median = (values[values.length / 2]+values[values.length / 2 - 1]) / 2;
	};

	// add to log
	print(current + " " + value + "  row " + first+1 + "-" + last+1 + " min: " + min + " max: " 
		+ max + " mean: " + mean + " std dev: " + std + " median: " + median);
		
	// add numbers to the results table
	for (i = first; i <= last; i++) {
		v = Table.get(value, i);
		Table.set("Mean(" + group + ")", i, mean);
		Table.set("Deviation(" + group + ")", i, - (mean - v)); // v - mean breaks on mac ?!
		Table.set("StdDev(" + group + ")", i, std);
		Table.set("Median" + group +")", i, median);
		Table.set("Min(" + group + ")", i, min);
		Table.set("Max(" + group + ")", i, max);
	}	
}


function copyMacro() {
	// this will not show unsaved changes, or changes in the macro name
	macroFileName = getDirectory("plugins")+"Macros\\Coloc_Macro.ijm"; // Set this to where your Macro is stored
	if (File.exists(macroFileName) && File.length(macroFileName) > 0) {
		print("This log file was likely generated with this macro: " + macroFileName);
		print("A copy of the source code is included below");
		print("Last Modified: " + File.dateLastModified(macroFileName) + "  File Length: " + File.length(macroFileName) +"\n\n");
		m = File.openAsString(macroFileName); 
		m = replace(m, "\\\t", "    "); // tabs vs spaces. Cosmetic reasons because log file doesn't handle tabs
		print(m); // append to log
	} else {
			print("...macro file not found: " + macroFileName);
	}
}


function printJavaProperties() {
	//Used for debugging various problems
	//requires("1.38m");
	print("####### Properties");
	print("Directory:  " + File.directory);

	keys = getList('java.properties');
	for (i=0; i<keys.length; i++)
		print(keys[i]+":  " + getInfo(keys[i]));
}

function h1(header) {
	//print a header
	print("\n\n" + l1);
	print(header);
	print(l1);
}

function h2(header) {
	//print a header
	print("\n" + l2);
	print(header);
}

function getTime() {
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString ="Date: "+DayNames[dayOfWeek]+" ";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+" Time: ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;
	return TimeString;  
} 


