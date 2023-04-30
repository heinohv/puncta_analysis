//This script lets you check settings to measure puncta!
Dialog.create("Measure puncta settings");
Dialog.addNumber("#of images to process (0=all)", 1);
Dialog.show();
number_of_images_to_process = Dialog.getNumber();

//making an array to print the titles of windows selected to be the "best"
good_settings = newArray(0);
VNC_folder = getDirectory("Choose the folder with your cropped VNC images");
VNC_files= getFileList(VNC_folder);

//if number of images to process is specified, only do that many images
if (number_of_images_to_process > 0) {
	photo_quantity = number_of_images_to_process;
}
//if number of images to process is unspecified, process all files
if (number_of_images_to_process == 0) {
	photo_quantity = VNC_files.length;
}

// default settings to load into the setting selection window
minimum_puncta_size = 8;
sigma = 0.1;
radius = 2;
method = "Phansalkar";
//images start being processed here
for (photo_number = 0; photo_number < photo_quantity; photo_number++) {
	open(VNC_folder+"/"+VNC_files[photo_number]);
	selectWindow(VNC_files[photo_number]);
	rename("RawData");
	setLocation(0, 0);
	run("In [+]");run("In [+]");
	a = 1;
	while (a > 0) {
		threshold_methods = newArray("Phansalkar","Bernsen");
		Dialog.create("Pick Settings");
		Dialog.addCheckbox("Retest", 1);
		Dialog.addNumber("Minimum Particle Size", minimum_puncta_size);
		Dialog.addNumber("Sigma", sigma);
		Dialog.addNumber("Radius", radius);
		Dialog.addChoice("Threshold method", threshold_methods, method);
		Dialog.show();

		a = Dialog.getCheckbox(); //continue
		minimum_puncta_size = Dialog.getNumber();
		sigma = Dialog.getNumber();
		radius = Dialog.getNumber();
		method = Dialog.getChoice();

		//clear ROIs in case new loop does not find new ones
		for (roi_index = 0; roi_index < roiManager("count"); roi_index++) {
			roiManager("Select", 0);
			roiManager("Deselect");
			roiManager("Delete");
		}
		//making a duplicate of the RAW data to build a mask from	
		selectWindow("RawData");
		run("Select None");
		run("Duplicate...", " ");
		rename("Watershed");
		setLocation(0, 100);

		//thresholding image
		selectImage("Watershed");
		resetMinAndMax();
		run("8-bit");
		run("Gaussian Blur...", "sigma="+sigma+"");
		run("Auto Local Threshold", "method="+method+" radius="+radius+" parameter_1=0 parameter_2=0 white");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Watershed");
		
		//turn the watershed image into ROIs outlined on the raw data
		selectWindow("Watershed");
		run("Analyze Particles...", "size="+minimum_puncta_size+"-Infinity show=Outlines clear add");
		setLocation(0, 200);
		//show new selections on the raw image
		selectWindow("RawData");
		roiManager("Show All");
		close("Watershed");
		close("Drawing of Watershed");
	}
	settings = "minimum_puncta_size_"+minimum_puncta_size+"_sigma_"+sigma+"_radius_"+radius+"_method_"+method;
	good_settings = Array.concat(good_settings, settings);
	run("Close All");
	}
for (i = 0; i < good_settings.length; i++) {
	print(good_settings[i]);
}
	
	
	
		
