#!/usr/bin/env bash




# NOTE: set to true for pure test, set to false for reusing some long build results
PURE_TEST=true






echo "Wait for tests to run... If any test fails this scrip will crash. Otherwise, you'll see 'All tests have passed' message."
echo "Using temporary directory '/tmp/no-headache-test/'"

set -e
set -euo pipefail
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

# Get the directory of this script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


ssh-add "$PROJECT_ROOT_DIR/secrets/sshkeys/example_ssh_key" &> /dev/null



# temporary directory for testing everything
mkdir -p /tmp/no-headache-test/
if $PURE_TEST; then
    rm -rf /tmp/no-headache-test/*
fi
cd /tmp/no-headache-test/



echo "Testing: nohead help"

nohead help &> help
nohead h &> h
# nohead helpppp &> /dev/null # fails, as it should (used for testing this tests)
nohead -h &> _-h
nohead --help &> _--help
nohead whatisgoingon &> whatisgoingon
nohead &> noarg
tail -n +3 noarg &> noarg2 # remove first two lines (warning no argument was provided)

# Compare outputs — everything should match 'help'
for f in h _-h _--help whatisgoingon noarg2; do
    # echo "Comparing help with $f..."
    diff -q help "$f" # the script will crash if files differ
done
echo "    - passed"




echo "Testing: nohead path"
nohead path &> /dev/null
echo "    - passed"


# Also testes diskImage option
echo "Testing: nohead build"
nohead build help &> help
nohead build h &> h
nohead build --help &> _--help
nohead build -h &> _-h
# Compare outputs — everything should match 'help'
for f in help h _-h _--help; do
    # echo "Comparing help with $f..."
    diff -q help "$f" # the script will crash if files differ
done

if $PURE_TEST; then
    nohead build -c "$PROJECT_ROOT_DIR#test-configs" --show-trace &> /dev/null
fi
if [ ! -e "result" ]; then
    echo "Error: result symlink not generated"
    exit 1
fi
# no image should be generated
if [ -e "result/aaa.qcow2" ] || [ -e "result/bbb.qcow2" ] || [ -e "result/bbb-1.qcow2" ] || [ -e "result/bbb-2.qcow2" ] || [ -e "result/ccc.qcow2" ]; then
    echo "Error: image generated when it shouldn't have"
    exit 1
fi
echo "    - passed (1/2)"

if $PURE_TEST; then
    nohead -r resultWithImages build -c "$PROJECT_ROOT_DIR#test-configs-images" &> /dev/null
fi
if [ ! -e "resultWithImages" ]; then
    echo "Error: resultWithImages symlink not generated"
    exit 1
fi
# machines with diskImage option should generate it (only one)
if [ -e "resultWithImages/aaa.qcow2" ] || [ -e "resultWithImages/bbb-1.qcow2" ] || [ -e "resultWithImages/bbb-2.qcow2" ] || [ -e "resultWithImages/ccc.qcow2" ]; then
    echo "Error: image generated when it shouldn't have"
    exit 1
fi
if [ ! -e "resultWithImages/bbb.qcow2" ]; then
    echo "Error: image resultWithImages/bbb.qcow2 not generated"
    # exit 1
fi
echo "    - passed (2/2)"







echo "Testing: nohead runall"
nohead list &> list
printf "" > list-expected
diff -q list list-expected # the script will crash if files differ

# NOTE: Not all options are tested
nohead runall &> /dev/null

sleep 3 # wait for them to start

nohead list &> list
echo "aaa" > list-expected
echo "bbb-1" >> list-expected
echo "bbb-2" >> list-expected
echo "ccc" >> list-expected
diff -q list list-expected # the script will crash if files differ
echo "    - passed"




echo "Testing: nohead list"
# already tested
echo "    - passed"




# use list and stop !!!
echo "Testing: nohead stopall"
nohead list &> list
echo "aaa" > list-expected
echo "bbb-1" >> list-expected
echo "bbb-2" >> list-expected
echo "ccc" >> list-expected
diff -q list list-expected # the script will crash if files differ

nohead stopall &> /dev/null

nohead list &> list
printf "" > list-expected
diff -q list list-expected # the script will crash if files differ
echo "    - passed"





echo "Testing: nohead run"
nohead list &> list
printf "" > list-expected
diff -q list list-expected # the script will crash if files differ

# NOTE: Not all options are tested
nohead run aaa &> /dev/null

nohead list &> list
echo "aaa" > list-expected
diff -q list list-expected # the script will crash if files differ

nohead -r resultWithImages run bbb-2 &> /dev/null

nohead list &> list
echo "aaa" > list-expected
echo "bbb-2" >> list-expected
diff -q list list-expected # the script will crash if files differ
echo "    - passed"






echo "Testing: nohead stop"
nohead list &> list
nohead stop bbb-2 &> /dev/null

nohead list &> list
echo "aaa" > list-expected
diff -q list list-expected # the script will crash if files differ

nohead stop aaa &> /dev/null

nohead list &> list
printf "" > list-expected
diff -q list list-expected # the script will crash if files differ
echo "    - passed"









echo "Testing: nohead init"
rm -rf ./no-headache # cleanup in case it exists from before
nohead init &> /dev/null
if [ ! -d "no-headache" ]; then
    echo "Error: nohead init failed"
    exit 1
fi
cd no-headache

# test default nohead build
nohead build

nohead runall
nohead list &> list
echo "empty" > list-expected
diff -q list list-expected # the script will crash if files differ

nohead stopall
cd ..
echo "    - passed"











echo "Testing: nohead ssh"
nohead runall &> /dev/null

sleep 10 # wait for machines to start
# nohead ssh will also wait for them to start

nohead ssh bbb-1 'echo $MACHINE_NAME' &> name-1
echo "bbb-1" > name-1-expected
diff -q name-1 name-1-expected
nohead ssh bbb-1 'echo $MACHINE_INDEX' &> index-1
echo "1" > index-1-expected
diff -q index-1 index-1-expected
nohead ssh bbb-2 'echo $MACHINE_INDEX' &> index-2
echo "2" > index-2-expected
diff -q index-2 index-2-expected
echo "    - passed"














echo ""
echo "Testing option: firstHostSshPort"
# Already tested
echo "    - passed"





echo "Testing option: username"
nohead ssh aaa 'whoami' &> out-real
echo "nixy" > out-expected
diff -q out-real out-expected
nohead ssh bbb-1 'whoami' &> out-real
echo "userrr" > out-expected
diff -q out-real out-expected
echo "    - passed"





echo "Testing option: count"
# Tested implicitly with bbb-1 and bbb-2
echo "    - passed"





echo "Testing option: nixos-config"
nohead ssh aaa "python -c 'print('py')'" 1> out-real 2> /dev/null
printf "" > out-expected
diff -q out-real out-expected
nohead ssh bbb-1 "python -c \"print('py')\"" &> out-real
echo "py" > out-expected
diff -q out-real out-expected
echo "    - passed"






echo "Testing option: nixos-config-virt"
if [ ! -f "ccc-init.script-result" ]; then
    echo "Error: ccc-init.script-result not fount!"
    exit 1
fi
printf "success" > out-expected
diff -q "ccc-init.script-result" out-expected
echo "    - passed"





echo "Testing option: init.script"
nohead ssh aaa 'touch test-init.txt ; cat test-init.txt' &> out-real
printf "" > out-expected
diff -q out-real out-expected
nohead ssh bbb-1 "cat test-init.txt" &> out-real
printf "from init script" > out-expected
diff -q out-real out-expected
echo "    - passed"





echo "Testing option: copyToHome"
nohead ssh bbb-1 'cat copyToHome-result' &> out-real
printf "success" > out-expected
diff -q out-real out-expected
nohead ssh bbb-1 "cat copiedFile" &> out-real
diff -q out-real "$PROJECT_ROOT_DIR/test/testFile"
nohead ssh bbb-1 "cat copiedDir/testFile2" &> out-real
diff -q out-real "$PROJECT_ROOT_DIR/test/testDir/testFile2"
echo "    - passed"





echo "Testing option: tailscaleAuthKeyFile"
sleep 10 # wait to ensure tailscale is initialized
echo "success" > out-expected
diff -q tailscale-test-result out-expected
echo "    - passed"







echo "Testing option: diskImage"
# Already tested
echo "    - passed"




# TODO: test the python compat env



echo "Testing examples"
# cd into directory built with nohead init
cd no-headache

# Copy secrets to ensure builds succeed
cp "$PROJECT_ROOT_DIR/secrets/tailscale.authkey" secrets/

nohead -r example1 build -c .#copy-to-home
echo "    - passed (1/7)"
nohead -r example2 build -c .#disk-images
echo "    - passed (2/7)"
nohead -r example3 build -c .#python
echo "    - passed (3/7)"
nohead -r example4 build -c .#server-client
echo "    - passed (4/7)"
nohead -r example5 build -c .#shared-dir
echo "    - passed (5/7)"
nohead -r example6 build -c .#ssh-from-host
echo "    - passed (6/7)"
nohead -r example7 build -c .#vm-count-option
echo "    - passed (7/7)"


nohead stopall &> /dev/null


echo ""
echo "All tests have passed"
echo "You might want to delete the temporary directory."




