Galaxy wrapper for OpenMS
=========================

OpenMS is an open-source software C++ library for LC/MS data management and analyses.
It offers an infrastructure for the rapid development of mass spectrometry related software.
OpenMS is free software available under the three clause BSD license and runs under Windows, MacOSX and Linux.

More informations are available at:

 * https://github.com/OpenMS/OpenMS
 * http://open-ms.sourceforge.net


Generating OpenMS wrappers
==========================

 * install OpenMS (you can do this automatically through Conda)
 * create a folder called CTD
 * if you installed openms as a binary in a specific directory, execute the following command in the `openms/bin` directory:
    
    ```bash
    for binary in `ls`; do ./$binary -write_ctd /PATH/TO/YOUR/CTD; done;
    ```
    
 * if there is no binary release (e.g. as with version 2.2), download and unpack the Conda package, find the `bin` folder and create a list of the tools as follow:
 
    ```bash
    ls >> tools.txt
    ```
    
 * search for the `bin` folder of your conda environment containing OpenMS and do:
 
    ```bash
    while read p; do
        ./PATH/TO/BIN/$p -write_ctd /PATH/TO/YOUR/CTD;
    done <tools.txt
    ```
    
 * You should have all CTD files now. `MetaProSIP.ctd` includes a not supported character: To use it, search for `²` and replace it (e.g. with `^2`).

 * clone or install CTDopts

    ```bash
    git clone https://github.com/genericworkflownodes/CTDopts
    ```

 * add CTDopts to your `$PYTHONPATH`

    ```bash
    export PYTHONPATH=/home/user/CTDopts/
    ```

 * clone or install CTD2Galaxy

    ```bash
    git clone https://github.com/WorkflowConversion/CTDConverter.git
    ```
    
 * If you have CTDopts and CTDConverter installed you are ready to generate Galaxy Tools from CTD definitions. Change the following command according to your needs, especially the `/PATH/TO` parts. The default files are provided in this repository. You might have to install `libxslt` and `lxml` to run it. Further information can be found on the CTDConverter page.

    ```bash
    python convert.py galaxy \ 
    -i /PATH/TO/YOUR/CTD/*.ctd \
    -o ./PATH/TO/YOUR/WRAPPERS/ -t tool.conf \
    -d datatypes_conf.xml -g openms \
    -b version log debug test no_progress threads \
     in_type executable myrimatch_executable \
     fido_executable fidocp_executable \
     omssa_executable pepnovo_e xecutable \
     xtandem_executable param_model_directory \
     java_executable java_memory java_permgen \
     r_executable rt_concat_trafo_out param_id_pool \
    -f /PATH/TO/filetypes.txt -m /PATH/TO/macros.xml \
    -s PATH/TO/tools_blacklist.txt
    ```


 * As last step you need to change manually the binary names of all external binaries you want to use in OpenMS. Some of these tools might already be deprecated and the files might not exist:

    ```
    sed -i '13 a\-fido_executable Fido' wrappers/FidoAdapter.xml
    sed -i '13 a\-fidocp_executable FidoChooseParameters' wrappers/FidoAdapter.xml
    sed -i '13 a\-myrimatch_executable myrimatch' wrappers/MyriMatchAdapter.xml
    sed -i '13 a\-omssa_executable omssa' wrappers/OMSSAAdapter.xml
    sed -i '13 a\-xtandem_executable xtandem' wrappers/XTandemAdapter.xml
    ```
    
 * For some tools, additional work has to be done. In `MSGFPlusAdapter.xml` the following is needed in the command section at the beginning (check your file to know what to copy where):
 
   ```
    <command><![CDATA[

    ## check input file type
    #set $in_type = $param_in.ext

    ## create the symlinks to set the proper file extension, since msgf uses them to choose how to handle the input files
    ln -s '$param_in' 'param_in.${in_type}' &&
    ln -s '$param_database' param_database.fasta &&
    ## find location of the MSGFPlus.jar file of the msgf_plus conda package
    MSGF_JAR=\$(msgf_plus -get_jar_path) &&

    MSGFPlusAdapter
    -executable \$MSGF_JAR
    #if $param_in:
      -in 'param_in.${in_type}'
    #end if
    #if $param_out:
      -out $param_out
    #end if
    #if $param_mzid_out:
      -mzid_out $param_mzid_out
    #end if
    #if $param_database:
      -database param_database.fasta
    #end if
    
    [...]
    ]]>
    ```
 
 * In Xtandem Converter and probably in others:
 
    ```
    #if str($param_missed_cleavages) != '':
    ```
    This is because integers needs to be compared as string otherwise `0` becomes `false`.
 
 * In `MetaProSIP.xml` add `R` as a requirement:
 
   ```
   <expand macro="requirements">
       <requirement type="package" version="3.3.1">r-base</requirement>
   </expand>
   ```
   
 * In `IDFileConverter.xml` the following is needed in the command section at the beginning (check your file to know what to copy where):
 
   ```
    <command><![CDATA[
   
      ## check input file type
      #set $in_type = $param_in.ext

      ## create the symlinks to set the proper file extension, since IDFileConverter uses them to choose how to handle the input files
      ln -s '$param_in' 'param_in.${in_type}' &&

      IDFileConverter

      #if $param_in:
        -in 'param_in.${in_type}'
      #end if

        [...]
        ]]>
    ```

 * In `IDFileConverter.xml` and `FileConverter.xml` add `auto_format="true"` to the output, e.g.:
 
   - `<data name="param_out" auto_format="true"/>`
   - `<data name="param_out" metadata_source="param_in" auto_format="true"/>`
        
 * To add an example test case to `DecoyDatabase.xml` add the following after the output section. If standard settings change you might have to adjust the options and/or the test files.
 
    ```
       <tests>
        <test>
            <param name="param_in" value="DecoyDatabase_input.fasta"/>
            <output name="param_out" file="DecoyDatabase_output.fasta"/>
        </test>
    </tests>
    ```
    
 * Additionally cause of lacking dependencies, the following adapters have been removed in `SKIP_TOOLS_FILES.txt` as well:
    * OMSSAAdapter
    * MyrimatchAdapter
    
 * Additionally cause of a problematic parameter (-model_directory), the following adapter has been removed:
    * PepNovoAdapter


Licence (MIT)
=============

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

