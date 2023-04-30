 //Used to go over the VNC images, to either keep, discard, or crop to impove data quality

//chose directory for input and output
userChosenDirectory = getDirectory("Choose the folder for images you want to check");
save_to = getDirectory("Choose the folder to save images that passed quality checks");

//
Dialog.create("Quality check settings");
Dialog.addCheckbox("Hide file name", 0);
Dialog.show();
hide_file_name = Dialog.getCheckbox();


//options for UI
choices = newArray("Keep","Toss", "Crop");

//loop through your VNC images
fileList = getFileList(userChosenDirectory);
for (file = 0; file < fileList.length; file++) {
	//open image in the specified file folder
	open(userChosenDirectory+"/"+fileList[file]);
		
	VNC_title= getTitle();
	VNC_window_name = VNC_title;
	
	if (hide_file_name == 1) {
		rename("hidden name");
		VNC_window_name = getTitle();
	}
		
	setLocation(0, 0);
	run("In [+]");run("In [+]");
	//ask the user what they want to do with the image
	Dialog.create("Quality Check");
	Dialog.addRadioButtonGroup("Keep, toss, or crop?", choices, 3, 1, "Keep");
	Dialog.show();
	user_choice = Dialog.getRadioButton;
	
	//if they want to keep it, save the file in the clean folder
	if (user_choice == "Keep") {
		saveAs("Tiff", save_to + VNC_title);
		VNC_window_name = getTitle();
		close(VNC_window_name);
		}
		
	//if they want to crop it, duplicate the selection they want, and save it to the clean folder
	if (user_choice == "Crop") {
		setTool("rectangle");
		waitForUser("Please select the section would would like to keep");
		run("Duplicate...", " ");
		saveAs("Tiff", save_to+VNC_title);
		close();
		close(VNC_window_name);
		}
	//if they want to toss it, just close it without saving
	if (user_choice == "Toss") {
		close(VNC_window_name);
		print("Not saving: "+ VNC_title);
		}
	//counter to keep track of how far through they are
	file_number = file +1;
	print("Image "+file_number+"/"+fileList.length);	
}
			

