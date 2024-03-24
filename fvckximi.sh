#!/bin/bash
dir=$(pwd)
repS="python3 $dir/bin/strRep.py"

get_file_dir() {
	if [[ $1 ]]; then
		sudo find $dir/ -name $1 
	else 
		return 0
	fi
}

jar_util() 
{

	if [[ ! -d $dir/jar_temp ]]; then
		mkdir $dir/jar_temp
	fi

	#binary
	bak="java -jar $dir/bin/baksmali.jar d"
	sma="java -jar $dir/bin/smali.jar a"

	if [[ $1 == "d" ]]; then
		echo -ne "====> Patching $2 : "

		if [[ $(get_file_dir $2 ) ]]; then
			sudo mv $(get_file_dir $2 ) $dir/jar_temp
			sudo chown $(whoami) $dir/jar_temp/$2
			unzip $dir/jar_temp/$2 -d $dir/jar_temp/$2.out  >/dev/null 2>&1
			if [[ -d $dir/jar_temp/"$2.out" ]]; then
				rm -rf $dir/jar_temp/$2
				for dex in $(sudo find $dir/jar_temp/"$2.out" -maxdepth 1 -name "*dex" ); do
						if [[ $4 ]]; then
							if [[ "$dex" != *"$4"* && "$dex" != *"$5"* ]]; then
								$bak $dex -o "$dex.out"
								[[ -d "$dex.out" ]] && rm -rf $dex
							fi
						else
							$bak $dex -o "$dex.out"
							[[ -d "$dex.out" ]] && rm -rf $dex		
						fi

				done
			fi
		fi
	else 
		if [[ $1 == "a" ]]; then 
			if [[ -d $dir/jar_temp/$2.out ]]; then
				cd $dir/jar_temp/$2.out
				for fld in $(sudo find -maxdepth 1 -name "*.out" ); do
					if [[ $4 ]]; then
						if [[ "$fld" != *"$4"* && "$fld" != *"$5"* ]]; then
							echo $fld
							$sma $fld -o $(echo ${fld//.out})
							[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld
						fi
					else 
						$sma $fld -o $(echo ${fld//.out})
						[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld	
					fi
				done
				7za a -tzip -mx=0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/. >/dev/null 2>&1
				#zip -r -j -0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/.
				zipalign -p -v 4 $dir/jar_temp/$2_notal $dir/jar_temp/$2 >/dev/null 2>&1
				if [[ -f $dir/jar_temp/$2 ]]; then
					rm -rf $dir/jar_temp/$2.out $dir/jar_temp/$2_notal 
					#sudo cp -rf $dir/jar_temp/$2 $(get_file_dir $2) 
					echo "Succes"
				else
					echo "Fail"
				fi
			fi
		fi
	fi
}


framework() {

	lang_dir="$dir/module/lang"

	jar_util d "framework.jar" fw classes classes2 

	#patch 

	s0=$(find -name "ApplicationPackageManager.smali")
	[[ -f $s0 ]] && sed -i '0,/# static fields/s//# static fields\n\n.field private static final blacklist featuresNexus:[Ljava\/lang\/String;\n.field private static final blacklist featuresPixel:[Ljava\/lang\/String;\n.field private static final blacklist featuresPixelOthers:[Ljava\/lang\/String;\n.field private static final blacklist featuresTensor:[Ljava\/lang\/String;\n.field private static final blacklist pTensorCodenames:[Ljava\/lang\/String;/' "$s0"

 
    	
	
	jar_util a "framework.jar" fw classes classes2
}

if [[ ! -d $dir/jar_temp ]]; then

	mkdir $dir/jar_temp
	
fi

framework

