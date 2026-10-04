curl -o openide.tar.gz https://download.openide.ru/262.9437.185.4/openIDE-262.9437.185.4.tar.gz
mkdir .data -p
tar -xavf openide.tar.gz -C .data
rm openide.tar.gz

DIR=$(ls .data)

mv .data/$DIR/* .data
rm .data/$DIR -r
