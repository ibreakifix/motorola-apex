#!/bin/zsh

#apextract1500.sh <flashdump.bin> <outputdir>
#Extract APEX 1500 images
#This script will extract an APEX flash dump into individual files so that they can be handled easier. 
#It will pack the rbf/img files in the factory directories, so that they may be processed via a vxworks bootp request in the future.
#Please see the apex FOF (file of files) in the manual for more info

INFILE=$1;
BLOCKSIZE=131072;
OUTDIR=$2;
BACKFILE="$1.backup"
#partmap is the start block, partsize is the number of blocks
#This partmap is for APEX using dual flash, so SW 2.x (presumably) use print_flash_status to find target system layout.
declare -A partmap=([qrmcal2]=588 [qrmfpga2]=589 [qrmfw2]=586 [cpld]=580 [qam4x4]=543 [gigeboot]=572 [appcode]=104 [gluefpga]=582 [dtifpga]=584 [qrmfw1]=613 [qrmcal1]=615 [qrmfpga1]=616 [encfpga]=640 [muxfpga]=744 [emgui]=848 [gigeapp]=880 [config3]=914 [config2]=915 [config1]=917 [config5]=535 [kernel]=919 );
declare -A partsize=([qrmcal2]=1 [qrmfpga2]=24 [qrmfw2]=2 [cpld]=2 [qam4x4]=28 [gigeboot]=8 [appcode]=81 [gluefpga]=2 [dtifpga]=2 [qrmfw1]=2 [qrmcal1]=1 [qrmfpga1]=24 [encfpga]=104 [muxfpga]=104 [emgui]=32 [gigeapp]=32 [config3]=1 [config2]=2 [config1]=2 [config5]=8 [kernel]=105 );

declare -A extractcommands=(
	[kernel]="mountAndExtractFATFS kernel; mv $OUTDIR/kernel $OUTDIR/appcode"
	[emgui]="mountAndExtractFATFS emgui"
	[config1]="mountAndExtractFATFS config1"
	[config2]="mountAndExtractFATFS config2"
	[config3]="mountAndExtractFATFS config3"
	[config5]="mountAndExtractFATFS config5"
	[qrmfw2]="cutRawFS qrmfw2"
	[qrmfw1]="cutRawFS qrmfw1"
	[qrmcal1]="cutRawFS qrmcal1"
	[qrmcal2]="cutRawFS qrmcal2"
	[qrmfpga1]="cutRawFS qrmfpga1"
	[qrmfpga2]="cutRawFS qrmfpga2"
	[qam4x4]="cutRawFS qam4x4"
	[muxfpga]="cutRawFS muxfpga"
	[gluefpga]="cutRawFS gluefpga"
	[gigeboot]="cutRawFS gigeboot"
	[gigeapp]="cutRawFS gigeapp"
	[encfpga]="cutRawFS encfpga"
	[dtifpga]="cutRawFS dtifpga"
	[cpld]="cutRawFS cpld; echo 'CPLD image is empty. Use JTAG probe to pull CPLD program.' > $OUTDIR/cpld/readme.txt"
);

mountAndExtractFATFS(){
	#If this runs on linux, use mount instead of hdiutil. mount on OS X does not support -o loop, so we can't use that.
	mkdir $OUTDIR/$1; 
	hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/$1.tmpimg; 
	cp -R /Volumes/Untitled/ $OUTDIR/$1/; 
	umount /Volumes/Untitled; 
	hdiutil detach /Volumes/Untitled;
}

cutRawFS(){
	HEXSIZE=$(tail -c8 $OUTDIR/$1.tmpimg | xxd -p | cut -c1-8)
	DECSIZE=$((16#$HEXSIZE))
	mkdir $OUTDIR/$1; 
	head -c+$DECSIZE $OUTDIR/$1.tmpimg > $OUTDIR/$1/$1.img
}

echo "Selected file: $INFILE";

if [ ! -f "$INFILE" ]; then
	echo "Failed: file does not exist.";
	exit;
fi

if [ -z "$OUTDIR" ]; then
	echo "apextract1500.sh <flashdump.bin> <outputdir>\nERROR: outputdir is missing";
	exit;
fi

if [ ! -f "$BACKFILE" ]; then
	echo "Creating backup: $BACKFILE";
	$(cp $INFILE $BACKFILE);
	if [ $? -eq 0 ]; then
		echo "Done!";
	else
		echo "Failed to create backup file";
		exit;
	fi
else
	echo "Backup file already exists at $BACKFILE";
fi

if [ ! -d "$OUTDIR" ]; then
echo "Creating output dir: $OUTDIR";
$(mkdir $OUTDIR);
if [ $? -eq 0 ]; then
	echo "Done!";
else
	echo "Failed to create output directory";
	exit;
fi
else
echo "Output dir already exists at: $OUTDIR";
fi

for key val in "${(@kv)partmap}"; do
	BYTESIZE=$(($partsize[$key]*$BLOCKSIZE));
	BYTEOFFSET=$(($val*$BLOCKSIZE));
	FILENAME=$OUTDIR/$key.tmpimg
	echo "=============================================\nWorking on: $key... $BYTESIZE bytes @ block $val"
	skip=$val
	echo "RunCmd: dd if=$INFILE of=$FILNAME bs=$BLOCKSIZE skip=$skip count=$partsize[$key] >./ddout.log 2>&1";
	$(dd if=$INFILE of=$FILENAME bs=$BLOCKSIZE skip=$skip count=$partsize[$key] >./ddout.log 2>&1)
	if [ $? -eq 0 ]; then
		echo "OK";
	else
		echo "Failed to create file.\n##############ddout.log##############";
		cat 'ddout.log';
		exit;
	fi
	echo "Running extract commands...";
	
		$(eval $extractcommands[$key]);
	
	if [ $? -eq 0 ]; then
		echo "Done!";
		rm -rf $FILENAME;
	else
		echo "Failed to extract";
	fi
done;