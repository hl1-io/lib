#!/usr/bin/env fish

function receive_file
    set incoming_data (mktemp)
    socat -u TCP-LISTEN:8010,reuseaddr OPEN:$incoming_data,creat

    set filename (head -n 1 $incoming_data)
    set tmp_content (mktemp)

    tail -n +2 $incoming_data >$tmp_content

    echo "Received file: $filename"
    rm $incoming_data

    switch $filename
        case '*.age'
            echo "Found age encrypted file"
            set outfile (basename -s .age $filename)
            age -i ~/.ssh/id_ed25519 -d -o $outfile $tmp_content
            if [ $status = 0 ]
                echo "Decrypted $filename, saved to $outfile"
            else
                echo "Failed to decrypt file! >> $filename <<"
            end
        case '*'
            echo 'File is not encrypted'
            cat $tmp_content >$filename
    end
    rm $tmp_content -f
    rm $incoming_data -f
end

while true
    receive_file
end
