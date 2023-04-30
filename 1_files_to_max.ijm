//this script will open a folder, and save all lif files/images inside of it as a tiff max projection is your selected output
lif_dir = getDirectory("Choose the folder with your lif/images files");
max_dir = getDirectory("Choose the folder to save your max projections");

run("Bio-Formats Macro Extensions");

processBioFormatFiles(lif_dir);
function processBioFormatFiles(currentDirectory) {
	fileList = getFileList(currentDirectory);
	for (file = 0; file < fileList.length; file++) {
		Ext.isThisType(currentDirectory + fileList[file], supportedFileFormat);
		if (supportedFileFormat=="true") {
			Ext.setId(currentDirectory + fileList[file]);
			Ext.getSeriesCount(seriesCount);
			for (series = 1; series <= seriesCount; series++) {
				run("Bio-Formats Importer", "open=[" + currentDirectory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+series);
	
				//remove any invalid characters from file name
				raw_title = getTitle();
				title = raw_title;
				title = replace(title, "\\", "_");
				title = replace(title, "/", "_");
				title = replace(title, ":", "_");
				title = replace(title, "*", "_");
				title = replace(title, "?", "_");
				title = replace(title, "<", "_");
				title = replace(title, ">", "_");
				title = replace(title, "|", "_");
				title = title;
				
				//if the image is a stack, create a max projection, save it, and close both windows
				getDimensions(width, height, channels, slices, frames);
				if (slices>1) {
					run("Z Project...", "projection=[Max Intensity]"); 
					saveAs("Tiff", max_dir+title);
					close();
					close(raw_title);
				}
				//if the image is not a stack, save it and close the window
				if (slices < 2) {
					saveAs("Tiff", max_dir+title);
					close();
				}
			}
			//open any subfolders, and run the above code on their contents
		} else if (endsWith(fileList[file], "/")) {
			processBioFormatFiles(currentDirectory + fileList[file]);
		}
	}
}
	
