// Copyright (c) 2024 Louis Perrochon
// This macro is provided under the MIT license.
// The MIT license in short grants anyone to do pretty much anything they want with it. 
//
// This Macro will call JACoP on an open tif file, or a directory of tif files of the form
// 
//     date name condition FOV.tif 
//
// with an ROI set in a file of the same name (including extension) + ".ROIset.zip" and store the results
// in a CSV file.

version = "V1.0" // change this if you change the code

// Default values you can set before running the script - but there is a dialog asking the user
var thra=8141 
var thrb=6081

var l2 = "======================================="
var l1 = l2+l2;

// Main

setBatchMode(true); 

// Clean up things
print("\\Clear");
run("Clear Results");

h1("Coloc_Macro "+ version + " " + getTime());
print("FIJI/ImageJ Version:  " + IJ.getFullVersion() 
	+ " (" + getInfo("os.name") + " " + getInfo("os.version") + ")" 
	+ " (Java: " + getInfo("java.version") + ")");

// Ask for parameters for JACoP
Dialog.create("Thresholds for Processing");
Dialog.addNumber("thra",thra);
Dialog.addNumber("thrb",thrb);
Dialog.show();
thra=Dialog.getNumber();
thrb=Dialog.getNumber();

if (nImages > 0) {
	// We have an active image. Process it
	processImage(getDirectory("image"), getTitle());
	h2("Finished Image: " + getTitle());
	outputPath = getDirectory("image")+getTitle();
} else {
	// No open image, ask for a directory
	folderPath = getDirectory("Choose a Directory");	
	processFolder(folderPath);
	outputPath = folderPath + "All";	
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
	print("thra = " + thra + "   thrb = " + thrb);

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
	print("Images processed: "+ count);

}

function processImage(directory, image) {
	// Call JACoP on all ROI of a single image
	h1("Processing image: " + image);
	print("thra = " + thra + "   thrb = " + thrb);
	print("Path:  " + directory + image);
	
	roiManager("reset");
	
	print("ROI set: " + directory + image + ".ROIset.zip");
	roiManager("open", directory + image + ".ROIset.zip");	
	count = roiManager("count");
	print("Number of ROIs: " + count);
	
	for (i=0; i<count; ++i) {
		// Here is the meat of what we do with each image
		roiManager("Select", i);
		h2("Processing ROI " + (i+1) + " " + Roi.getName());
		run("Duplicate...", "duplicate channels=1-2");
		run("Clear Outside");
		region = getTitle();
		print("Region: "+region);
		run("Split Channels");
		c1 = "C1-"+ region;
		c2 = "C2-"+ region;
		argument = "imga=[" + c1 + "] imgb=[" + c2 + "] get_pearson thra=" + thra + " thrb=" + thrb + " get_mm";
		print("Arguments: " + argument);
		run("JACoP ", argument);
		close("C*");
		print("Completed ROI " + (i+1));
	}
}


function finishUp(outputPath) {
	// Post process log and finish everything up
	
	h1("Analysis complete, finishing up");
	
	// Generate a table and then from that a CSV file by parsing the log file
	h2("Generating csv:  " + outputPath + ".Results.JACoP.csv");
	processLog(outputPath + ".Results.JACoP.csv");
	
	// Attempt to copy the source code of the macro to the log file for documentation
	// If you can't get this to run, comment out the next two lines.
	h2("Attempting to append Macro to log");
	copyMacro();
	
	// we print a time stamp before saving the log so have it in the log
	h2("Macro finished at: " + getTime()); 
	
	// Saving the log file
	h2("Log saved at:  " + outputPath + ".Log.JACoP.txt");
	selectWindow("Log");
	saveAs("Text", outputPath + ".Log.JACoP.txt");
}


function processLog(path) {
	// Parse the log and make a table and save as a CSV
	// If you change the log file output, you may need to change this parse, too.
	selectWindow("Log");
	logContent = getInfo("log");
	logLines = split(logContent, "\n");
	
	Table.create("Log_Window_Values");
	row = 0;
	for (i = 0; i < logLines.length; i++) {
		if (startsWith(logLines[i], "Processing image:")){
			// This section parses the file name of the current image
			// The sample files look something like: Processing image: 022924 cHeLa DMSO FOV1-1.tif
			// Which can be read as <date> <experiment> <condition> <field_of_view>.tif 
			// Anything you rename, add or remove here needs to be reflected in the last case
			// We split the line from the log by spaces
			s = split(logLines[i]); 
			// The array is 0 based, so s[0] is "Processing" and s[1] is "image:"
			date = s[2]; 
			experiment = s[3];
			condition = s[4];
			fov = s[5];
			fov = replace(fov,".tif",""); // this is how we remove the .tif at the end. Keep this 
			fov = replace(fov,"-1",""); // then we also remove the -1 for our example data
			filename = s[2]+" "+s[3]+" "+s[4]+" "+s[5]; // this is the filename we will put into the table
			roi = 1; // We have a new file, so we set ROI (back) to 1
		}
		if (startsWith(logLines[i], "r=")) {
			pearson = substring(logLines[i], indexOf(logLines[i], "=")+1);
		}
		if (startsWith(logLines[i], "M1=")) {
			m1 = substring(logLines[i], indexOf(logLines[i], "=")+1, indexOf(logLines[i], " "));
		}
		if (startsWith(logLines[i], "M2=")) {
			m2 = substring(logLines[i], indexOf(logLines[i], "=")+1, indexOf(logLines[i], " "));
		}
		if (startsWith(logLines[i], "Completed")) {
			Table.set("Date", row, date);
			Table.set("Experiment", row, experiment);
			Table.set("Condition", row, condition);
			Table.set("FOV", row, fov);
			Table.set("ROI", row, roi);
			Table.set("Pearson", row, pearson);
			Table.set("M1", row, m1);
			Table.set("M2", row, m2);
			Table.set("Thra", row, thra);
			Table.set("Thrb", row, thrb);
			Table.set("Filename", row, filename);
			row++;
			roi++;
		}
	}
	Table.save(path);
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


