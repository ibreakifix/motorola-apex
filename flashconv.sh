#!/bin/zsh

#flashconv.sh <text.txt> <flashdump.bin>
#xxd didn't work on its own, so this uses a cut piped to xxd... it expects bytes in the text file to be between col 14 and 52
#Quick convert of telnet hex dumps to bin files

INFILE=$1;
OUTNAME=$2

if [ -z "$INFILE" ]; then
	echo "flashconv.sh <input-filename.txt> <output-filename.bin>\nERROR: Input filename is missing";
	exit;
fi
if [ -z "$OUTNAME" ]; then
	echo "flashconv.sh <input-filename.txt> <output-filename.bin>\nERROR: Output filename is missing";
	exit;
fi

echo "Selected file: $INFILE";
echo "Output file: $OUTNAME";


if [ ! -f "$INFILE" ]; then
	echo "flashconv.sh <input-filename.txt> <output-filename.bin>\nERROR: Input file does not exist.";
	exit;
fi

echo "Running..."

$(cut -c14-52 $INFILE | xxd -r -p - $OUTNAME);
if [ $? -eq 0 ]; then
	echo "Done!";
else
	echo "Failed to convert file.";
fi