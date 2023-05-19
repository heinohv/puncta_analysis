//This script is used to make the input data for '2_measure_puncta'
//It will crop/straighten the VNC into a rectangle
//chose your file paths
max_dir = getDirectory("Choose the folder your uncropped max projections are");
fileList = getFileList(max_dir);
vnc_dir = getDirectory("Choose the folder to save your cropped VNC images");


//Settings:
//open the first image in the file to extract the units (e.g. microns)
open(max_dir+fileList[0]);
getPixelSize(unit, pixelWidth, pixelHeight);
close();
Dialog.create("worm to VNC settings");
Dialog.addNumber("Line width ("+unit+")", 1);
Dialog.addCheckbox("Hide file name", 0);
Dialog.show();
user_selected_line_width = Dialog.getNumber();
hide_file_name = Dialog.getCheckbox();



//loop to open each image from the folder with max projections
for (file = 0; file < fileList.length; file++) {
	open(max_dir+fileList[file]);
	
	//converting user selected line width into pixels 
	getPixelSize(unit, pixelWidth, pixelHeight);
	line_width = user_selected_line_width  / pixelWidth;
	run("Line Width...", "line="+line_width);
	
	full_worm_title= getTitle();
	full_worm_window_name = full_worm_title;
	
	if (hide_file_name == 1) {
		rename("hidden name");
		full_worm_window_name = getTitle();
	}
	
	//have the user draw a line along the area they want to measure
	setTool("polyline");
	file_number = file+1;
	waitForUser("Trace the VNC (Image "+file_number+" of "+fileList.length+") \n Press ok without drawing a line if you want to don't want to use this image");
	
	//check if there is a polyline
	is_there_a_line = selectionType();
	
	//if there is a line, straighten and crop around it, and save to the VNC directory
	if (is_there_a_line == 6 ) {
		run("Straighten...");
		saveAs("Tiff", vnc_dir+full_worm_title);
		VNC_window = getTitle();
		close(full_worm_window_name);
		close(VNC_window);
	}
	//if there is no selection, close the window (use this to discard low quality images)
	if (is_there_a_line == -1) {
			close(full_worm_window_name);
			print("Not saving: " + full_worm_title); 
	}
}



