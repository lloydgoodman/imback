#!/bin/bash                                                                                                                                                                                          [1857/1916]
# version 1.0 LBG 200510
                                                                                                                                                                                                                
# Give an opportunity to cancel if you run it by accident                                                                                                                                                       
echo "Will start the image backup script in 3 seconds..."                                                                                                                                                       
sleep 3                                                                                                                                                                                                         
                                                                                                                                                                                                                
if [ ! -f ./list.txt ]; then                                                                                                                                                                                    
    echo "input file missing, exiting"                                                                                                                                                                          
    exit                                                                                                                                                                                                        
fi                                                                                                                                                                                                              
                                                                                                                                                                                                                
for wholepath in `cat ./list.txt`                                                                                                                                                                               
do                                                                                                                                                                                                              
                                                                                                                                                                                                                
        thename=`basename $wholepath`                                                                                                                                                                           
	echo "-------------------------------------"
	echo "$thename"
	echo "-------------------------------------"
	lvs --noheadings $wholepath
                                                                                                                                                                                                                
        #                                                                                                                                                                                                       
        # create snapshot                                                                                                                                                                                       
        #                                                                                                                                                                                                       
        thesnapshot=${thename}-lbg-snap-delete                                                                                                                                                                  
        snapFullPath=${wholepath}-lbg-snap-delete                                                                                                                                                               
        if [ -f $snapFullPath ]; then                                                                                                                                                                           
                echo "snapshot already present, exiting"                                                                                                                                                        
                exit                                                                                                                                                                                            
        fi                                                                                                                                                                                                      
		
        echo "Creating the snapshot using - lvcreate -s -L 1G -n $thesnapshot $wholepath"
	# KEY PART <-------------
        lvcreate -s -L 1G -n $thesnapshot $wholepath                                                                                                                                                           
        if [ $? -ne 0 ]                                                                                                                                                                                         
        then                                                                                                                                                                                                    
                echo "snapshot creation failed, exiting"                                                                                                                                                        
                exit                                                                                                                                                                                            
        fi                                                                                                                                                                                                      

	echo "calculating the checksum of the snapshot...."
	snapchecksum=`md5sum $snapFullPath | awk {'print $1'}`
        if [ $? -ne 0 ]
        then
                echo "snapshot checksum calculation failed, exiting"
                exit
        fi
	echo $snapchecksum
                                                                                                                                                                                                                
        #                                                                                                                                                                                                       
        # write out the file                                                                                                                                                                                    
        #                                                                                                                                                                                                       
        datestamp=`date +%y%m%d`                                                                                                                                                                                
        theimage=${thename}-${snapchecksum}-${datestamp}.img
        #if [ -f $theimage ]; then                                                                                                                                                                            
        #        echo "image already present, exiting"     
        #       exit                                                                                                                                                                                            
        #fi
        # 
	#echo "Creating the image using the command - dd if=$snapFullPath of=$theimage conv=excl"
	# KEY PART <---------------
        #dd if=$snapFullPath of=$theimage conv=excl                                                                                                                                                             
        #if [ $? -ne 0 ]
        #then
        #        echo "image creation failed, exiting"
        #        exit
        #fi
        #
        #echo "Checking the checksums"
        #md5sum $snapFullPath
        #md5sum $theimage

	echo "creating image using dd if=$snapFullPath and dd of=/imppc/sysadmin/lgoodman/gameraImages/$theimage"
	# KEY PART <---------------
	dd if=$snapFullPath | ssh lgoodman@chi "dd of=/imppc/sysadmin/lgoodman/gameraImages/$theimage"
        if [ $? -ne 0 ]
        then
                echo "image copy failed, exiting"
                exit
        fi

                                                                                                                                                                                                                
	#
        # remove snapshot
        #

	echo "Removing the snapshot using the command - lvremove -y $snapFullPath"

        # check it has delete in the name
	ls $snapFullPath | grep delete
	if [ $? -ne 0 ]
	then
		echo "The snapshot to be deleted doesnt appear to have delete in the name, need to check, exiting"
	        exit
	fi

        # check the lvm is a snapshot
	lvdisplay $snapFullPath | grep "LV snapshot status     active destination"
	if [ $? -ne 0 ]
	then
		echo "The logical volume to be deleted doesnt appear to be a snapshot, need to check, exiting"
	        exit
	fi

	# KEY PART <--------------
        #lvremove -y $snapFullPath
        lvremove $snapFullPath
        if [ $? -ne 0 ]
        then
                echo "snapshot delete failed, exiting"
                exit
        fi

done
