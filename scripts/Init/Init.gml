function Init()
{
	midx = room_width/2;
	
	GenASCII();
	
	Initlists(true);
	
	Run();
}

function Initlists(alllists = false)
{
	if alllists or mouse_x <= midx
		badfiles = [];
	
	if alllists or mouse_x > midx
		goodfiles = [];
}

function Run()
{
	var totalimages = 0;
	
	var filename = get_open_filename("PNG files|*.png","");
	if filename != ""
	{
		files = [];
		path = filename_path(filename);
		var mask = path + "*.png";
		mask = string_replace_all(mask, "\\", "/");
		var file_name = file_find_first(mask, fa_none);
		
		while (file_name != "")
		{
			array_push(files, file_name);
			totalimages++;
			file_name = file_find_next();
		}
		
		file_find_close();
		
		for (var i = 0; i < totalimages; i++)
		{
			if CheckFile(path, files[i])[0]
			array_push(badfiles, path + files[i]);
			else array_push(goodfiles, path + files[i]);
		}
		
		if array_length(badfiles) > 0
		{
			// if we've found at least one bad file then make a copy of the good files
			// too so we have a complete copy of the files on the fixed folder
			for (var i = 0; i < array_length(goodfiles); i++)
			{
				var file = file_bin_open(goodfiles[i], 0);
				TrimFile(file, -1, -1, path, goodfiles[i]);
			}
		}
	}
}

function CheckFile(path, filename)
{
	//show_debug_message("Try loading a file")
	var fullname = path + filename;
	show_debug_message(fullname);
	var file = file_bin_open(fullname, 0);
	
	var filesize = file_bin_size(file);
	//show_debug_message("File size " + string(filesize));
	
	var offset = 8; // skip standard PNG header
	
	var chunks = [];
	
	var  byte, chunkname, chunkcrc;
	
	var hasiccp = false;
	var iccpdata = [];
	
	// parse it
	var chunklen = 0;
	while offset < filesize
	{
		//show_debug_message("read chunk at " + string(offset));
		
		file_bin_seek(file, offset);
		byte = file_bin_read_byte(file);
		chunklen += byte * 256 * 256 * 256;
		byte = file_bin_read_byte(file);
		chunklen += byte * 256 * 256;
		byte = file_bin_read_byte(file);
		chunklen += byte * 256;
		byte = file_bin_read_byte(file);
		chunklen += byte;
		
		chunkname = hextoascii(file_bin_read_byte(file));
		chunkname += hextoascii(file_bin_read_byte(file));
		chunkname += hextoascii(file_bin_read_byte(file));
		chunkname += hextoascii(file_bin_read_byte(file));
		
		//show_debug_message(chunkname, chunklen);
		
		if chunkname == "iCCP"
		{
			//show_debug_message("error, COLOR PROFILE DETECTED");
			hasiccp = true;
			iccpdata = [offset, chunklen];
			
			//var bakname = path + filename_name(filename) + "(old with iCCP).png";
			//file_copy(filename, bakname);
			
			TrimFile(file, offset, chunklen + 4 + 4 + 4, path, filename);
			
			return [hasiccp, iccpdata];
		}
		
		offset += 4 + 4 + 4 + chunklen ; // length, name, crc, data
		
		chunklen = 0; // reset for the next chunk
	}
	
	file_bin_close(file);
	
	return [hasiccp, iccpdata];
}

function dec_to_hex_cpuver(dec)
{
	var hex, h, byte, hi, lo;
	if (dec) hex = "" else hex="00";
	h = "0123456789ABCDEF";
	while (dec) {
	    byte = dec & $FF;
	    hi = string_char_at(h, byte div 16 + 1);
	    lo = string_char_at(h, byte mod 16 + 1);
	    hex = hi + lo + hex;
	    dec = dec >> 8;
	}
	return hex;
}

function TrimFile(file, offset, chunklen, path, filename)
{
	//file_bin_open(file, 0);
	var size = file_bin_size(file);
	var buff = buffer_create(size, buffer_u8, 1);
	buffer_seek(buff, buffer_seek_start, 0);
	file_bin_seek(file, 0);
	
	var i = 0
	var byte;
	while i < size
	{
		var byte = file_bin_read_byte(file);
		//show_debug_message(string(i) + ", " + string(dec_to_hex_cpuver(byte)) + ", " + hextoascii(byte));
		if i < offset or i >= offset + chunklen
		buffer_write(buff, buffer_u8, byte);
		//else show_debug_message("skip");
		i++;
	}
	
	file_bin_close(file);
	
	var fixname = path + "fixed (iCCP removed)/" + filename_name(filename);
	buffer_save(buff, fixname);
	buffer_delete(buff);
}

function hextoascii(hexbytes)
{
	hexbytes = clamp(hexbytes, 0, 255);
	//show_debug_message(hexbytes);
	//show_debug_message(chars3[hexbytes]);
	return chars3[hexbytes];
}

function GenASCII()
{
	for (var i = 0; i < 32; i++)
		chars[i] = "-";
		
	chars2 = [
	" ", "!", " ", "#", "$" ,"%", "&",
	"'", "(", ")", "*", "+" ," ", " ",
	".", "/", "0", "1", "2" ,"3", "4",
	"5", "6", "7", "8", "9" ,":", ";",
	"<", "=", ">", "?", "@" ,"A", "B",
	"C", "D", "E", "F", "G" ,"H", "I",
	"J", "K", "L", "M", "N" ,"O", "P",
	"Q", "R", "S", "T", "U" ,"V", "W",
	"X", "Y", "Z", "[", " " ,"]", "^",
	"_", "`", "a", "b", "c" ,"d", "e",
	"f", "g", "h", "i", "j" ,"k", "l",
	"m", "n", "o", "p", "q" ,"r", "s",
	"t", "u", "v", "w", "x" ,"y", "z",
	];

	chars3 = array_concat(chars, chars2);
	
	for (var i = array_length(chars3); i < 256; i++)
		chars3[i] = "-";
}

function Main()
{
	if mouse_check_button(mb_left) 
	{
		Run();
	}
	else if mouse_check_button(mb_right)
	{
		Initlists();
	}
	else if mouse_check_button(mb_middle)
	{
		Copy();
	}
	else if keyboard_check_pressed(vk_escape)
	{
		game_end();
	}
}

function Copy()
{
	var bad = true;
	if mouse_x > midx bad = false;
		
	if bad var str = "Bad files with Photoshop ICC Profile:##";
	else var str = "Good files without Photoshop ICC Profile:##";
	
	var arr = badfiles;
	if !bad arr = goodfiles
	var filenum = array_length(arr);
		
	for (var i = 0; i < filenum; i++)
	{
		str += arr[i] + "#";
	}
	
	str = string_hash_to_newline(str);
	
	clipboard_set_text(str);
}

function Draw()
{
	for (var i = 0; i < array_length(badfiles); i++)
	{
		draw_set_color(c_yellow);
		draw_text(10, i * 20, badfiles[i]);
	}

	for (var i = 0; i < array_length(goodfiles); i++)
	{
		draw_set_color(c_lime);
		draw_text(midx, i * 20, goodfiles[i]);
	}
	
	draw_set_color(c_lime);
	draw_text(10, room_height - 20, "Left button: load images - Middle Button: copy a list to the clipboard - Right Button: Clear a list");
}