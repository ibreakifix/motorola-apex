#!/bin/zsh

#apextract.sh <flashdump.bin>
#Binwalk isn't really working on this flash dump so here we are...
#This script will extract an APEX flash dump into individual files so that they can be handled easier. 
#It will pack the rbf/img files in the factory directories, so that they may be processed via a vxworks bootp request in the future.
#Please see the apex FOF (file of files) in the manual for more info

INFILE=$1;
BLOCKSIZE=131072;
OUTDIR="./output"
BACKFILE="$1.backup"
#partmap is the start block, partsize is the number of blocks

#getAppFiles indicates appfiles dir is at block 104 but it appears to actually be at 422?

declare -A partmap=([spare1]=0 [qrmfpga]=34 [gigeboot]=99 [appcode]=104 [gluefpga]=185 [dtifpga]=187 [qrmfw]=189 [qrmcal]=191 [spare2]=192 [mpc2gx60]=204 [mpc2mux]=215 [spare3]=222 [muxfpga1]=318 [emgui]=366 [gigeapp]=382 [config3]=416 [config2]=418 [config1]=420 [kernel]=422 );
declare -A partsize=([spare1]=34 [qrmfpga]=65 [gigeboot]=5 [appcode]=81 [gluefpga]=2 [dtifpga]=2 [qrmfw]=2 [qrmcal]=1 [spare2]=12 [mpc2gx60]=11 [mpc2mux]=7 [spare3]=96 [muxfpga1]=48 [emgui]=16 [gigeapp]=32 [config3]=1 [config2]=2 [config1]=2 [kernel]=90 );

#Right now just extract the kernel and other DOS fs. 
#If this runs on linux, use mount instead of hdiutil. mount on OS X does not support -o loop, so we can't use that.
#The QRM & FPGA extraction commands will be added later once we have a more up to date fw image, as on our current APEX the qrm partitions are empty.
declare -A extractcommands=(
	[kernel]="mkdir $OUTDIR/appcode; hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/kernel.tmpimg; cp -R /Volumes/Untitled/ $OUTDIR/appcode/; umount /Volumes/Untitled"
	[emgui]="mkdir $OUTDIR/emgui; hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/emgui.tmpimg; cp -R /Volumes/Untitled/ $OUTDIR/emgui/; umount /Volumes/Untitled"
	[config1]="mkdir $OUTDIR/config1; hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/config1.tmpimg; cp -R /Volumes/Untitled/ $OUTDIR/config1/; umount /Volumes/Untitled"
	[config2]="mkdir $OUTDIR/config2; hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/config2.tmpimg; cp -R /Volumes/Untitled/ $OUTDIR/config2/; umount /Volumes/Untitled"
	[config3]="mkdir $OUTDIR/config3; hdiutil attach -imagekey diskimage-class=CRawDiskImage $OUTDIR/config3.tmpimg; cp -R /Volumes/Untitled/ $OUTDIR/config3/; umount /Volumes/Untitled" 
);



echo "Selected file: $INFILE";

if [ ! -f "$INFILE" ]; then
	echo "Failed: file does not exist.";
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
	#binwalk -z -o $BYTEOFFSET -l $BYTESIZE $INFILE;
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
		#rm -rf $FILENAME;
	else
		echo "Failed to extract";
	fi
done;