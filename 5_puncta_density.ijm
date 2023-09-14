//Analyzes puncta for full width half max, intensity, etc. 
threshold_methods = newArray("Phansalkar","Bernsen");

Dialog.create("Measure puncta settings");
Dialog.addCheckbox("Manually check each ROI", 0);
Dialog.addNumber("#of images to process (0=all)", 0);
Dialog.addNumber("Minimum accepted puncta size", 0.3);
Dialog.addNumber("Sigma", 0.75);
Dialog.addNumber("Radius", 1);
Dialog.addChoice("Threshold method", threshold_methods, threshold_methods[0]);

Dialog.addString("Table name", "Puncta_density");
Dialog.show();

check_each_ROI = Dialog.getCheckbox();
number_of_images_to_process = Dialog.getNumber();
minimum_puncta_size = Dialog.getNumber();
sigma = Dialog.getNumber();
radius = Dialog.getNumber();
method = Dialog.getChoice();
table_name = Dialog.getString();

//select the folder with VNCs you want to analyze
VNC_folder = getDirectory("Choose the folder with your cropped VNC images");

VNC_files= getFileList(VNC_folder);

//creating table and initializing an index to let us move through each row
Table.create(table_name);
table_index_counter = 0;

//if number of images to process is specified, only do that many images
if (number_of_images_to_process > 0) {
	photo_quantity = number_of_images_to_process;
}
//if number of images set to process is 0, process all files
if (number_of_images_to_process == 0) {
	photo_quantity = VNC_files.length;
}

//loop to open the photos
for (photo_number = 0; photo_number < photo_quantity; photo_number++) {
	open(VNC_folder+"/"+VNC_files[photo_number]);
	selectWindow(VNC_files[photo_number]);
	print("Processing photo " + (photo_number+1) + " of " + photo_quantity);
	
	//getting name of image to record in the table later
	image_name = getTitle();

	rename("Watershed");
	setLocation(0, 0);

	//duplicates data to measure from
	run("Duplicate...", " ");
	rename("RawData");
	setLocation(0, 100);
	
	//Nerriahs thresholding settings
	selectImage("Watershed");
	resetMinAndMax();
	run("8-bit");
	run("Gaussian Blur...", "sigma="+sigma);
	run("Auto Local Threshold", "method="+method+" radius="+radius+" parameter_1=0 parameter_2=0 white");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Watershed");
	
	//create ROI's for each bright spot
	run("Analyze Particles...", "size="+minimum_puncta_size+"-Infinity show=Outlines clear add");
	setLocation(0, 200);
	
	//count the number of puncta
	number_of_puncta = roiManager("count");
	
	//measuring the width of the image
	getPixelSize(unit, pixelWidth, pixelHeight);
	getDimensions(width, height, channels, slices, frames);
	width_microns = width * pixelWidth;

	//calculating the number of puncta/micron
	puncta_density = (number_of_puncta / width_microns);	

	//entering data into a table
	Table.set("genotype", table_index_counter, "");
	Table.set("image_name", table_index_counter, image_name);
	Table.set("number_of_puncta", table_index_counter, number_of_puncta);
	Table.set("width of image (pixels)", table_index_counter, width);
	Table.set("width of image (microns)", table_index_counter, width_microns);
	Table.set("Pixel Width (microns)", table_index_counter, pixelWidth);
	Table.set("puncta_density", table_index_counter, puncta_density);
	
	//recording settings used in analysis in the table
	Table.set("sigma", table_index_counter, sigma);
	Table.set("radius", table_index_counter, radius);
	Table.set("method", table_index_counter, method);
	Table.set("minimum puncta size", table_index_counter, minimum_puncta_size);
	
	//closing the other windows out
	close("Watershed");
	close("RawData");
	close("Drawing of Watershed");
	close("Roi Manager");;
	close(image_name);
	// moving to the next row in the table
	table_index_counter += 1;
}




