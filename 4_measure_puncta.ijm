//Analyzes puncta for full width half max, intensity, etc. 
threshold_methods = newArray("Phansalkar","Bernsen");

Dialog.create("Measure puncta settings");
Dialog.addCheckbox("Manually check each ROI", 0);
Dialog.addNumber("#of images to process (0=all)", 0);
Dialog.addNumber("Minimum accepted puncta size", 0.3);
Dialog.addNumber("Sigma", 0.75);
Dialog.addNumber("Radius", 1);
Dialog.addChoice("Threshold method", threshold_methods, threshold_methods[0]);

Dialog.addString("Table name", "Puncta_size");
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
	print(image_name);

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
	
	//for loop to move through each region of interest (ROI)
	for (roi_index = 0; roi_index < roiManager("count"); roi_index++) {
		
		//getting dimensions of the window, so we know how many pixels to loop through
		selectWindow("RawData");
		width = getWidth;
		height = getHeight;
		pixel_count = width*height;
		
		//getting the pixel to micron conversion so FWHM can be recorded in microns
		getPixelSize(unit, pixelWidth, pixelHeight);

		//select ROI to measure
		roiManager("Select", roi_index);
		getStatistics(ROI_int_area, ROI_int_mean, ROI_int_min, ROI_int_max, std, histogram);
		//calculating total brightness of ROI to record later
		ROI_total_int = ROI_int_area*ROI_int_mean;
		
		//making arrays to store x values and pixel intensity
		ROI_x_values = newArray;
		ROI_pixel_intensities = newArray;
		
		//for loop scans across all pixels, recording X-values paired to intensity, if they are within the ROI
		for (x_pixel_cord = 0; x_pixel_cord < width; x_pixel_cord++) {
			for (y_pixel_cord = 0; y_pixel_cord < height; y_pixel_cord++) {
				//see if pixel is within ROI, if it is, record them
				in_roi = Roi.contains(x_pixel_cord, y_pixel_cord);
				if (in_roi == 1) {
					ROI_x_values = Array.concat(ROI_x_values, x_pixel_cord);
					//add pixel values into array "ROI_pixel_intensities"
					pixel_value = getPixel(x_pixel_cord, y_pixel_cord);
					ROI_pixel_intensities = Array.concat(ROI_pixel_intensities, pixel_value);
				}
			}
		}
		
		//calculates width of ROI
		Array.getStatistics(ROI_x_values, x_roi_min, x_roi_max, mean, stdDev);
		ROI_width = x_roi_max - x_roi_min;
		
		//making empty array to store intensity for each column of pixels
		summed_insensity = newArray(ROI_width+1);
		//making index to keep track of which unique x value we are on
		summed_insensity_index = 0;
		//keeping track of which column we are in
		current_x = ROI_x_values[0];
		
		//adding up all intensities with the same X value, and storing them in the summed intensity array
		for (j = 0; j < ROI_x_values.length; j++) {
			if (current_x != ROI_x_values[j]) {
				current_x = ROI_x_values[j];
				summed_insensity_index+=1;
			}
			if (current_x == ROI_x_values[j]) {
				summed_insensity[summed_insensity_index]+=ROI_pixel_intensities[j];
			}
		}
		
		//makes an array of all unique x values (e.g. 4,5,6,7,8) so our graph matches our array
		unique_x_values = newArray;
		for (unique_x_value = x_roi_min; unique_x_value < (ROI_width + x_roi_min +1); unique_x_value++) {
			unique_x_values = Array.concat(unique_x_values, unique_x_value);
		}
		
		//plot total of each x value intensity to each x value
		Plot.create("ROI_summed_by_x", "X value", "summed pixel intensity", unique_x_values, summed_insensity);
		Plot.update();
		selectWindow("ROI_summed_by_x");
		
		//fits a gaussian model to the data, and takes parameters from it
		Plot.getValues(xpoints, ypoints);
		Fit.doFit("Gaussian", xpoints, ypoints);
		Fit.plot;
			a = Fit.p(0);
			b = Fit.p(1);
			c = Fit.p(2);
			d = Fit.p(3);

		//taking Y values from model to calc half max
		Array.getStatistics(ypoints, plot_ymin, plot_ymax, mean, stdDev);
		half_max = (plot_ymax+plot_ymin)/2;//(peak of the plot+min of the plot / 2) puts us at the halfway point

		//This is where full width of half max is calculated
		//gaussian equation solved for X (2 times to solve for the left and right of curve)
		x_left = -d*pow(-log(pow((-1*(a/(b-a))+(half_max/(b-a))), 2)), 0.5)+c;
		x_right = d*pow(-log(pow((-1*(a/(b-a))+(half_max/(b-a))), 2)), 0.5)+c;
		full_width = x_right-x_left;
		full_width_microns = full_width * pixelWidth;
		
		//making a window zoomed in on the current ROI if user selected they want to check each one
		if (check_each_ROI ==1) {
			roiManager("Select", roi_index);
			Roi.getCoordinates(xpoints, ypoints);
			Array.getStatistics(xpoints, roi_x_min, roi_x_max, mean, stdDev);
			Array.getStatistics(ypoints, roi_y_min, roi_y_max, mean, stdDev);
			selectWindow("RawData");
			
			x_buffer = 0;
			y_buffer = 0;
			makeRectangle(roi_x_min-x_buffer, roi_y_min-y_buffer, (roi_x_max-roi_x_min+x_buffer), (roi_y_max-roi_y_min+y_buffer));
			run("Duplicate...", "test");
			rename("ROI zoomed in");
			run("In [+]");run("In [+]");run("In [+]");run("In [+]");run("In [+]");run("In [+]");run("In [+]");
			waitForUser("ROI index:"+roi_index +"\nHalf max: "+half_max+"\nFull width: " + full_width+"\nROI width: " +  ROI_width + "("+x_left+" to "+x_right+")");
			close("ROI zoomed in");
		}

		//entering data into a table
		Table.set("genotype", table_index_counter, "");
		Table.set("image_name", table_index_counter, image_name);
		Table.set("roi_index", table_index_counter, roi_index);
		Table.set("full_width_half_max", table_index_counter, full_width);
		Table.set("full_width_half_max_microns", table_index_counter, full_width_microns);
		Table.set("ROI_width", table_index_counter, ROI_width);
		Table.set("plt ymax", table_index_counter, plot_ymax);
		Table.set("plt ymin", table_index_counter, plot_ymin);
		Table.set("ROI total intensity", table_index_counter, ROI_total_int);
		Table.set("ROI total area", table_index_counter, ROI_int_area);
		Table.set("ROI max intensity", table_index_counter, ROI_int_max);
		Table.set("PixelWidth", table_index_counter, pixelWidth);
		
		//recording settings used in analysis in the table
		Table.set("sigma", table_index_counter, sigma);
		Table.set("radius", table_index_counter, radius);
		Table.set("method", table_index_counter, method);
		Table.set("minimum puncta size", table_index_counter, minimum_puncta_size);
		
		//FWHM is > ROI, record "discard" as 1 so it can be removed in post
		if (ROI_width>full_width) {
			Table.set("discard", table_index_counter, 0);
		}
		if (ROI_width<=full_width) {
			Table.set("discard", table_index_counter, 1);
		}
		//moving to next row in table
		table_index_counter += 1;
		
		//closing out the graphs
		close("y = a + (b-a)*exp(-(x-c)*(x-c)/(2*d*d))");
		close("ROI_summed_by_x");
	}
	//closing the other windows out
	close("Watershed");
	close("RawData");
	close("Drawing of Watershed");
	close("Roi Manager");;
	close(image_name);
}

