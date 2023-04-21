# подготовка
# создаем каталоги
mkdir -p ~/Fuzzing/pdftojson/scr ~/Fuzzing/pdftojson/bin ~/Fuzzing/pdftojson/inout/in ~/Fuzzing/pdftojson/inout/asan/ ~/Fuzzing/pdftojson/inout/ubsan/
#запускаем контейнер
docker run -ti --name pdftojson -v /home/$USER/Fuzzing/pdftojson:/fuzz aflplusplus/aflplusplus 
# в контейнере
cd /fuzz/scr
git clone https://github.com/ldenoue/pdftojson.git
cd pdftojson
git checkout master -f
#скачивание репозитория с корпусами тестовых данных
git clone https://github.com/openpreserve/format-corpus.git
# Собираем ОО со стат инструментированием и санитайзерами
export AFL_USE_ASAN=1
export AFL_USE_UBSAN=1
CC=afl-gcc CXX=afl-g++ \
CFLAGS=" -O0 -g3" CXXFLAGS="-O0 -g3" \
./configure --prefix=/fuzz/bin/ --with-freetype2-library=/usr/lib/ \
--with-freetype2-includes=/usr/include/freetype2/ \
--disable-shared --enable-threads=no 
make -j$(nproc)
#установка
make install
#тесты make check (заменяем перебором входных корпусов)
./xpdf/pdftojson ./format-corpus/pdf-handbuilt-test-corpus/T02-02_005_page-tree-no-kids.pdf test_000.json
for i in ./format-corpus/pdf-handbuilt-test-corpus; do echo $i && ./xpdf/pdftojson $i $i.json; done
./xpdf/pdftojson -v
#Сборка "обертки" целевых функций pdftojson (создаем на основе одной из cpp)
cd ..
ls
nano pdftojson-fuzz.cpp

#запускаем тест
afl-g++ -O0 -g -I /fuzz/bin/include pdftojson-fuzz.cpp -L /fuzz/bin/lib -l:fuzz/bin/pdftojson-fuzz
