#!/bin/bash
########################################################################
#
# author:  Xavier Janssen                                09/27/2011
# purpose: Interface script to higgs Limit code
#
########################################################################

cfg="NULL"
sub=0
get=0
plt=0
kil=0
batch=0
ext='.card'
#ext='.txt'

for arg in $* ; do
  case $arg in 
    -cfg)  cfg=$2 ; shift ; shift ;;
    -sub)  sub=1          ; shift ;;
    -batch)batch=1        ; shift ;;
    -get)  get=1          ; shift ;;
    -kill) kil=1        ; shift ;; 
    -plot) plt=1         ; shift ;;
  esac
done 

# ------------------------  READ CFG --------------------------------------------
parse_config()
{

  pwd 
  cat $cfg
  if [ ! -f $cfg ];then
    echo -e "${RED}[mkLimit] ERROR :${DEF} The config file $cfg you specified doesn't exist !"
    exit
  fi

  # choose queue
  if    [ `uname -a | grep 'iihe.ac.be' | wc -l` -eq 1 ];then
    LABO='IIHE'
#   queueName='localgrid@cream01'
  elif  [ `uname -a | grep 'cern.ch' | wc -l` -eq 1 ];then
    LABO='CERN'
#   queueName='8nh'
  else
    echo "Warning , don't know were you are, correct before starting subjob."
    exit -1
  fi

  # Limit Name
  grep LimitName  $cfg -q && LimitName=`(   cat $cfg | grep LimitName  | awk -F"=" '{print $2}' | sed "s: ::g")` || exit
  grep LimTitle   $cfg -q && LimTitle=`(  cat $cfg | grep LimTitle | awk -F"=" '{print $2}'               )` || LimTitle=$LimitName

  # Data Inputs
  grep CardDir    $cfg -q && CardDir=`(     cat $cfg | grep CardDir    | awk -F"=" '{print $2}' | sed "s: ::g")` || CardDir=LimitCards
  grep PrefixCard $cfg -q && PrefixCard=`(  cat $cfg | grep PrefixCard | awk -F"=" '{print $2}' | sed "s: ::g")` || exit
  grep SuffixCard $cfg -q && SuffixCard=`(  cat $cfg | grep SuffixCard | awk -F"=" '{print $2}' | sed "s: ::g")` || exit
  grep UseShape   $cfg -q && UseShape=`(    cat $cfg | grep UseShape   | awk -F"=" '{print $2}' | sed "s: ::g")` || UseShape=0
  grep ShapeFiles $cfg -q && ShapeFiles=`(  cat $cfg | grep ShapeFiles | awk -F"=" '{print $2}')` ; UseShape=2   || UseShape=1
  grep MassPoints $cfg -q && MassPoints=`(  cat $cfg | grep MassPoints | awk -F"=" '{print $2}' | sed "s: ::g" | sed "s:\:: :g")` || exit

  # Limit Code Options
  # grep LimCodeDir  $cfg -q && LimCodeDir=`(  cat $cfg | grep LimCodeDir | awk -F"=" '{print $2}' | sed "s: ::g")` || exit
  if   [ "$LABO" == "IIHE" ] ; then
    LimCodeDir="/localgrid/xjanssen/CMSSW_4_2_8/src"
  elif [ "$LABO" == "CERN" ] ; then
    LimCodeDir="/afs/cern.ch/user/x/xjanssen/scratch0/UALimit/CMSSW_4_2_8/src"
  fi
  grep MethodLimit $cfg -q && MethodLimit=`( cat $cfg | grep MethodLimit| awk -F"=" '{print $2}' | sed "s: ::g")` || MethodLimit=ProfileLikelihood
  grep MthdOptCom  $cfg -q && MthdOptCom=`(  cat $cfg | grep MthdOptCom | awk -F"=" '{print $2}'               )` || MthdOptCom=''
  grep MthdOptObs  $cfg -q && MthdOptObs=`(  cat $cfg | grep MthdOptObs | awk -F"=" '{print $2}'               )` || MthdOptObs=''
  grep MthdOptExp  $cfg -q && MthdOptExp=`(  cat $cfg | grep MthdOptExp | awk -F"=" '{print $2}'               )` || MthdOptExp=''
  grep DoObsLimit  $cfg -q && DoObsLimit=`(  cat $cfg | grep DoObsLimit | awk -F"=" '{print $2}' | sed "s: ::g")` || DoObsLimit=1
  grep DoExpLimit  $cfg -q && DoExpLimit=`(  cat $cfg | grep DoExpLimit | awk -F"=" '{print $2}' | sed "s: ::g")` || DoExpLimit=1
  grep ExpLimNIter $cfg -q && ExpLimNIter=`( cat $cfg | grep ExpLimNIter| awk -F"=" '{print $2}' | sed "s: ::g")` || ExpLimNIter=100

  grep rMaxList    $cfg -q && rMaxList=`( cat $cfg | grep rMaxList      | awk -F"=" '{print $2}' )`                  || rMaxList=''
  grep rMinList    $cfg -q && rMinList=`( cat $cfg | grep rMinList      | awk -F"=" '{print $2}' )`                  || rMinList=''

  # Splitting jobs Options
  grep SplitSwitch $cfg -q && SplitSwitch=`( cat $cfg | grep SplitSwitch| awk -F"=" '{print $2}' | sed "s: ::g")` || SplitSwitch=0 
  grep SplitObsLim $cfg -q && SplitObsLim=`( cat $cfg | grep SplitObsLim| awk -F"=" '{print $2}'               )` || SplitObsLim='1 1 1'
  grep SplitExpLim $cfg -q && SplitExpLim=`( cat $cfg | grep SplitExpLim| awk -F"=" '{print $2}'               )` || SplitExpLim='101 101 1'

  ObsSplitStart=`(echo $SplitObsLim | awk '{print $1}')`
  ObsSplitEnd=`(echo $SplitObsLim | awk '{print $2}')`
  ObsSplitStep=`(echo $SplitObsLim | awk '{print $3}')`
  ExpSplitStart=`(echo $SplitExpLim | awk '{print $1}')`
  ExpSplitEnd=`(echo $SplitExpLim | awk '{print $2}')`
  ExpSplitStep=`(echo $SplitExpLim | awk '{print $3}')`


  UseShape=1
  
  echo
  echo '---------------------------------------'
  echo 'LimitName   : ' $LimitName
  echo '--------Data Inputs--------------------'
  echo 'CardDir     : ' $CardDir
  echo 'PrefixCard  : ' $PrefixCard
  echo 'SuffixCard  : ' $SuffixCard
  echo 'UseShape    : ' $UseShape $ShapeFiles
  echo 'MassPoints  : ' $MassPoints
  echo '--------Limit Code Options-------------'
  echo 'MethodLimit : ' $MethodLimit
  echo 'DoObsLimit  : ' $DoObsLimit
  echo 'DoExpLimit  : ' $DoExpLimit
  echo 'MthdOptCom  : ' $MthdOptCom  
  echo 'MthdOptObs  : ' $MthdOptObs  
  echo 'MthdOptExp  : ' $MthdOptExp
  echo 'ExpLimNIter : ' $ExpLimNIter
  echo 'rMaxList    : ' $rMaxList
  echo 'rMinList    : ' $rMinList
  echo '--------Splitting jobs Options---------'
  echo 'SplitSwitch : ' $SplitSwitch
  echo 'SplitObsLim : ' $SplitObsLim
  echo 'SplitExpLim : ' $SplitExpLim
  echo '---------------------------------------'
  echo




}

# ------------------------  SUBMIT  JOB(S) --------------------------------------
sub_limit()
{
  BaseDir=`pwd`
  mkdir -p LimitResults/$LimitName/$CardDir
  cd       LimitResults/$LimitName 

  if [ $batch -ne 0 ] ; then 
    lockFile=$LimitName'_'$MethodLimit'.lock'
    if [ -f $lockFile ] ; then
      echo '[mkLimit.sh] ERROR lockFile exist:' `pwd`/$lockFile
      exit
    fi
  fi   

  if [ $batch -eq 0 ] ; then 
    export SCRAM_ARCH=slc5_amd64_gcc434
    source $VO_CMS_SW_DIR/cmsset_default.sh
    cd $LimCodeDir ; eval `scramv1 runtime -sh` ; cd -
  else
    btaskFile='btask_'$LimitName'.cfg'
    cp /dev/null $btaskFile
    echo 'taskName  = UALimit'                                                >> $btaskFile
    echo 'inDir     = '`pwd`                                                  >> $btaskFile
    echo `pwd`
    if [ "$UseShape" == "2" ] ; then 
      AllShapeFiles=`(echo $ShapeFiles | sed "s:XXX:*:g")`
      #echo 'inList    = '$CardDir'/* , ' $AllShapeFiles                       >> $btaskFile
      echo 'inList    = ' >> $btaskFile
      echo $AllShapeFiles
      #return
    else
      echo 'inList    = '$CardDir'/*.job'  >> $btaskFile
      #echo 'inList    = '$CardDir'/*'                                           >> $btaskFile
    fi
    echo 'outDir    = '`pwd`                                                  >> $btaskFile
    echo 'outList   = "higgsCombine_*.root" , "*.ExpLimit" , "*.ObsLimit"'    >> $btaskFile
    echo 'execBase  = cd LimitCards4.63fb-mll ; cp /afs/cern.ch/user/x/xjanssen/scratch0/UALimit/LimitCards4.63fb-mll/*  .; cd - ; source '$VO_CMS_SW_DIR'/cmsset_default.sh ; cd '$LimCodeDir' ; ls ; eval `scramv1 runtime -sh` ; cd - '   >> $btaskFile 
    EXECMULT='execMult   = '
  fi
 
  echo "Submitting ..."
  FirstJob=1
  for mass in $MassPoints ; do  
    # Prepare job.x files
    Const=''   
    for rMax in $rMaxList ; do
 
      rMass=`(echo $rMax | awk -F":" '{print $1}')`
      rVal=`(echo $rMax | awk -F":" '{print $2}')`
      if [ "$mass" == "$rMass" ] ; then
        Const=$Const' --rMax '$rVal
      fi
    done
    for rMin in $rMinList ; do
      rMass=`(echo $rMin | awk -F":" '{print $1}')`
      rVal=`(echo $rMin | awk -F":" '{print $2}')`
      if [ "$mass" == "$rMass" ] ; then
        Const=$Const' --rMin '$rVal
      fi
    done
    echo 'Mass = '$mass' --> Constraints : '  $Const 

    if [ $SplitSwitch -eq 0 ] ; then
      job=$CardDir/$mass'.'$MethodLimit'.job'
      cp /dev/null $job
      if [ $batch -eq 1 ] ; then
        if [ $FirstJob -eq 1 ] ; then
          FirstJob=0
          EXECMULT=$EXECMULT' source '$job 
        else
          EXECMULT=$EXECMULT' ; source '$job
        fi 
      fi
    else
      job=$CardDir/$mass'.'$MethodLimit'.all.job'
      cp /dev/null $job
      #echo LimitResults/$LimitName/$job
      if [ $DoObsLimit -gt 0 ] ; then
        for (( Start=$ObsSplitStart; Start<=$ObsSplitEnd; Start=$(expr $Start + $ObsSplitStep) )) ; do
          End=$(expr $Start + $ObsSplitStep)
          End=$(expr $End - 1    )
          #echo $Start $End
          jobi=$CardDir/$mass'.'$MethodLimit'.Obs_'$Start'_'$End'.job'
          cp /dev/null $jobi
          echo 'source' $jobi' &' >> $job 
          if [ $batch -eq 1 ] ; then
            if [ $FirstJob -eq 1 ] ; then
              FirstJob=0
              EXECMULT=$EXECMULT' source '$jobi
            else
              EXECMULT=$EXECMULT' ; source '$jobi
            fi
          fi
        done
      fi
      if [ $DoExpLimit -gt 0 ] ; then
        for (( Start=$ExpSplitStart; Start<=$ExpSplitEnd; Start=$(expr $Start + $ExpSplitStep) )) ; do
          End=$(expr $Start + $ExpSplitStep)
          End=$(expr $End - 1    )
          #echo $Start $End
          jobi=$CardDir/$mass'.'$MethodLimit'.Exp_'$Start'_'$End'.job'
          cp /dev/null $jobi
          echo 'source' $jobi' &' >> $job
          if [ $batch -eq 1 ] ; then
            if [ $FirstJob -eq 1 ] ; then
              FirstJob=0
              EXECMULT=$EXECMULT' source '$jobi
            else
              EXECMULT=$EXECMULT' ; source '$jobi
            fi
          fi
        done
      fi
      #echo $EXECMULT
      
    fi

    echo $BaseDir/$CardDir'/'$PrefixCard$mass$SuffixCard$ext
    cp $BaseDir/$CardDir'/'$PrefixCard$mass$SuffixCard$ext $CardDir'/'$PrefixCard$mass$SuffixCard$ext 
    if [ $UseShape  -gt 0 ] ; then
      if [ "$UseShape" == "1" ] ; then 
        echo cp $BaseDir/$CardDir'/'$PrefixCard$mass$SuffixCard'.root' $CardDir'/'$PrefixCard$mass$SuffixCard'.root' 
        pwd
        #cp $BaseDir/$CardDir'/'$PrefixCard$mass$SuffixCard'.root' $CardDir'/'$PrefixCard$mass$SuffixCard'.root'
        cp $BaseDir/$CardDir'/'*'.root' $CardDir'/.'
      else
        for ShapeFileTemplate in $ShapeFiles ; do
          ShapeFile=`(echo $ShapeFileTemplate | sed "s:XXX:$mass:")`  
          #mkdir $CardDir'/shapes'
          cp $BaseDir/$CardDir'/'$ShapeFile $CardDir'/'$ShapeFile   
          #cp $BaseDir/$CardDir'/'$ShapeFile .
        done
      fi
    fi
    if [ $DoObsLimit -gt 0 ] ; then
      if [ $SplitSwitch -eq 0 ] ; then
        outfile=$LimitName'_'$MethodLimit'_'$mass'.ObsLimit'
        if [ "$MethodLimit" == "Asymptotic" ] ; then
          EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptObs $Const' --run=observed -m '$mass' -n _'$LimitName'.Obs' $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile)
        else 
          EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptObs $Const' -m '$mass' -n _'$LimitName'.Obs' $CardDir'/'$PrefixCard$mass$SuffixCard$ext '  > '$outfile)
        fi
        echo $EXEC >> $job
      else
        for (( Start=$ObsSplitStart; Start<=$ObsSplitEnd; Start=$(expr $Start + $ObsSplitStep) )) ; do
          End=$(expr $Start + $ObsSplitStep)
          End=$(expr $End - 1    )
          jobi=$CardDir/$mass'.'$MethodLimit'.Obs_'$Start'_'$End'.job'
          for (( iSeed=$Start ; iSeed<=$End ; ++iSeed )) ; do
            #echo $Start $End $iSeed
            outfile=$LimitName'_'$MethodLimit'_'$mass'.'$iSeed'.ObsLimit'
            if [ "$MethodLimit" == "Asymptotic" ] ; then
              EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptObs $Const' --run=observed -s '$iSeed' -m '$mass' -n _'$LimitName $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile)
            else
              EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptObs $Const' -s '$iSeed' -m '$mass' -n _'$LimitName $CardDir'/'$PrefixCard$mass$SuffixCard$ext '  > '$outfile)
            fi   
            echo $EXEC >> $jobi 
          done
        done 
      fi
    fi
    if [ $DoExpLimit -gt 0 ] ; then
      if [ $SplitSwitch -eq 0 ] ; then
        outfile=$LimitName'_'$MethodLimit'_'$mass'.ExpLimit'
        if [ "$MethodLimit" == "Asymptotic" ] ; then
          EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' --run=expected -m '$mass '-n _'$LimitName'.Exp' $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile) 
          #EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' -m '$mass '-n _'$LimitName'.Exp' $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile) 
        else
          #EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' -m '$mass '-n _'$LimitName'.Exp' $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' -t '$ExpLimNIter' > '$outfile)
          EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' -m '$mass '-n _'$LimitName'.Exp' $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile)
        fi
        echo $EXEC >> $job
      else
        for (( Start=$ExpSplitStart; Start<=$ExpSplitEnd; Start=$(expr $Start + $ExpSplitStep) )) ; do
          End=$(expr $Start + $ExpSplitStep)
          End=$(expr $End - 1    )
          jobi=$CardDir/$mass'.'$MethodLimit'.Exp_'$Start'_'$End'.job'
          for (( iSeed=$Start ; iSeed<=$End ; ++iSeed )) ; do
            #echo $Start $End $iSeed
            outfile=$LimitName'_'$MethodLimit'_'$mass'.'$iSeed'.ExpLimit'
            if [ "$MethodLimit" == "Asymptotic" ] ; then
              EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' --run=expected -s '$iSeed' -m '$mass '-n _'$LimitName $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' > '$outfile)
            else
              #EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' -s '$iSeed' -m '$mass '-n _'$LimitName $CardDir'/'$PrefixCard$mass$SuffixCard$ext ' -t '$ExpLimNIter' > '$outfile)
              EXEC=$(echo 'combine -M '$MethodLimit $MthdOptCom $MthdOptExp $Const' -s '$iSeed' -m '$mass '-n _'$LimitName $CardDir'/'$PrefixCard$mass$SuffixCard$ext '  > '$outfile)
            fi
            echo $EXEC >> $jobi
          done
        done 
      fi
    fi
    
    if [ $batch -eq 0 ] ; then
      source $job 
      pwd
      #echo $job
      cat $job
    fi
    
  done


  if [ $batch -eq 1 ] ; then
    echo $EXECMULT >> $btaskFile
    btaskName=`(btask -submit $btaskFile | grep "started:" | awk -F'started:' '{print $2}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"  )`
    echo $btaskName > $lockFile
  fi 
}

# ------------------------  GET  JOB(S) --------------------------------------

get_limit()
{

  BASEDIR=`pwd`
  cd       LimitResults/$LimitName

  lockFile=$LimitName'_'$MethodLimit'.lock'
  if [ -f $lockFile ] ; then
    btaskName=`(cat $lockFile)`
    btask -status -s -t $btaskName
    status=`(btask -status -s -bw -t $btaskName | grep $btaskName)`
    declare -i nFinished
    declare -i nCrashed
    declare -i nTotal
    nFinished=`(echo $status | awk '{print $2}')`
    nCrashed=`( echo $status | awk '{print $3}')`
    nTotal=`(   echo $status | awk '{print $6}')`
    if [ $nCrashed -gt 0 ] ; then
      echo "----> Some jobs crashed !!!! "
      #exit
    fi
    if [ $nTotal -ne $nFinished ] ; then
      echo "----> Not all jobs are DONE !!!!"
      #exit
    fi
    btask -get -t $btaskName -force -norename -nojobid -def y
    rm $lockFile
  fi

  # Extract Limits from job summarys 
  if [ $SplitSwitch -eq 0 ] ; then

    iJob=''
    DoObsLimitLoc=$DoObsLimit
    DoExpLimitLoc=$DoExpLimit
    extract_limit_simple 
 
  else
  
    # ... Observed 
    if [ $DoObsLimit -gt 0 ] ; then
      for (( jjob=$ObsSplitStart ; jjob<=$ObsSplitEnd ; ++jjob )) ; do
        DoObsLimitLoc=1
        DoExpLimitLoc=0
        iJob='.'$jjob
#       extract_limit_simple 
      done
    fi

    # ... Expected 
    if [ $DoExpLimit -gt 0 ] ; then
      for (( jjob=$ExpSplitStart ; jjob<=$ExpSplitEnd ; ++jjob )) ; do
        DoObsLimitLoc=0
        DoExpLimitLoc=1
        iJob='.'$jjob
#       extract_limit_simple 
      done
    fi
#   average_limit_simple

  fi  

  # Extract Limit bands from root file
  
  if [ $SplitSwitch -eq 0 ] ; then
    RootFile='higgsCombine_'$LimitName'.All.'$MethodLimit'.AllmH.root'
    ObsRootFile='dummy'
    ExpRootFile='dummy'
    if [ $DoObsLimit -gt 0 ] ; then
      ObsRootFile='higgsCombine_'$LimitName'.Obs.'$MethodLimit'.AllmH.root'
      echo hadd -f $ObsRootFile 'higgsCombine_'$LimitName'.Obs.'$MethodLimit'.mH'*'.root' 
    fi
    if [ $DoExpLimit -gt 0 ] ; then
      ExpRootFile='higgsCombine_'$LimitName'.Exp.'$MethodLimit'.AllmH.root'
      echo hadd -f $ExpRootFile 'higgsCombine_'$LimitName'.Exp.'$MethodLimit'.mH'*'.root' 
    fi
    if   [ $DoObsLimit -gt 0 ] && [ $DoExpLimit -gt 0 ] ; then
      echo hadd -f $RootFile $ObsRootFile $ExpRootFile
    elif [ $DoObsLimit -gt 0 ] ; then
      cp $ObsRootFile $RootFile 
    elif [ $DoExpLimit -gt 0 ] ; then
      cp $ExpRootFile $RootFile 
    fi
  else
    RootFile='higgsCombine_'$LimitName'.All.'$MethodLimit'.AllmH.root'
    for mass in $MassPoints ; do 
      Files=`(ls 'higgsCombine_'$LimitName'.'$MethodLimit'.mH'$mass'.'*'.root')`

#      iFirstRootFile=0
#      for iRootFile in $Files ; do
#        echo $iRootFile
#        if [ "$iFirstRootFile" == "0" ] ; then
#          cp $iRootFile hadd2.root
#          iFirstRootFile=1 
#        else 
#          hadd -f hadd2.root hadd1.root $iRootFile
#        fi  
#        mv hadd2.root hadd1.root
#      done

      nRootFile=0
      RootFileList=''
      iFirstRootFile=0
      for iRootFile in $Files ; do
        RootFileList=$RootFileList' '$iRootFile
        nRootFile=$(expr $nRootFile + 1 )
        if [ "$nRootFile" == "200" ] ; then
          if [ "$iFirstRootFile" == "0" ] ; then
            hadd -f hadd2.root $RootFileList
            iFirstRootFile=1 
          else 
            hadd -f hadd2.root hadd1.root $RootFileList 
          fi
          mv hadd2.root hadd1.root
          RootFileList=''
          nRootFile=0
        fi
      done
      hadd -f hadd2.root hadd1.root $RootFileList
      mv hadd2.root 'higgsCombine_'$LimitName'.All.'$MethodLimit'.mH'$mass'.All.root'
      #echo hadd -f 'higgsCombine_'$LimitName'.All.'$MethodLimit'.mH'$mass'.All.root' 'higgsCombine_'$LimitName'.'$MethodLimit'.mH'$mass'.'*'.root' 
    done
    #hadd -f $RootFile 'higgsCombine_'$LimitName'.All.'$MethodLimit'.mH'*'.All.root' 
  fi

  LimSummary=$LimitName'_'$MethodLimit'.bands.summary'
  BandsFile=$LimitName'_'$MethodLimit'.bands.root'
  if [ "$MethodLimit" == "Asymptotic" ] ; then
    cp $LimitName'_'$MethodLimit'.summary' $LimSummary
  else
    root -b -l -q $BASEDIR/src/bandUtils.cxx+ $BASEDIR/src/extractLimit.cxx"(\"$LimSummary\",\"$RootFile\",\"$BandsFile\",$DoObsLimit,$DoExpLimit)"
  fi
  

}

average_limit_simple()
{
  LimSummary=$LimitName'_'$MethodLimit'.summary'
  LimSumBase=$LimitName'_'$MethodLimit'.'
  root -l -q $BASEDIR/src/average_limit_simple.C+"(\"$LimSummary\",\"$LimSumBase\",$DoObsLimit,$ObsSplitStart,$ObsSplitEnd,$DoExpLimit,$ExpSplitStart,$ExpSplitEnd)"
}

extract_limit_simple()
{

  LimSummary=$LimitName'_'$MethodLimit$iJob'.summary'
  cp /dev/null $LimSummary
  for mass in $MassPoints ; do
    if [ "$MethodLimit" == "Asymptotic" ] ; then
      if [ $DoObsLimitLoc -gt 0 ] ; then
        limfile=$LimitName'_'$MethodLimit'_'$mass$iJob'.ObsLimit'
        ObsLimit=`(cat $limfile | grep "Limit:" | awk '{print $5}')` 
      else      
        ObsLimit=99.
      fi      
      if [ $DoExpLimitLoc -gt 0 ] ; then
        limfile=$LimitName'_'$MethodLimit'_'$mass$iJob'.ExpLimit'
        MeanExpLimit=99.
        MedianExpLimit=`( cat $limfile | grep "Median for expected limits:" | awk '{print $5}')`
        ExpLim95Down=`(   cat $limfile | grep "Expected  2.5%:"    | awk '{print $5}')`
        ExpLim68Down=`(   cat $limfile | grep "Expected 16.0%:"    | awk '{print $5}')`
        ExpLim68Up=`(     cat $limfile | grep "Expected 84.0%:"    | awk '{print $5}')`
        ExpLim95Up=`(     cat $limfile | grep "Expected 97.5%:"    | awk '{print $5}')`
      else
        MeanExpLimit=99.
        MedianExpLimit=99.
        ExpLim68Down=99.
        ExpLim68Up=99.
        ExpLim95Down=99.
        ExpLim95Up=99.
      fi
    else
      if [ $DoObsLimitLoc -gt 0 ] ; then
        limfile=$LimitName'_'$MethodLimit'_'$mass$iJob'.ObsLimit'
        ObsLimit=`(cat $limfile | grep "Limit:" | awk '{print $4}')` 
      else      
        ObsLimit=99.
      fi
      if [ $DoExpLimitLoc -gt 0 ] ; then
        limfile=$LimitName'_'$MethodLimit'_'$mass$iJob'.ExpLimit'
        MeanExpLimit=`(   cat $limfile | grep "mean   expected limit:" | awk '{print $6}')`
        MedianExpLimit=`( cat $limfile | grep "median expected limit:" | awk '{print $6}')`
        ExpLim68Down=`(   cat $limfile | grep "68% expected band :"    | awk '{print $5}')`
        ExpLim68Up=`(     cat $limfile | grep "68% expected band :"    | awk '{print $9}')`
        ExpLim95Down=`(   cat $limfile | grep "95% expected band :"    | awk '{print $5}')`
        ExpLim95Up=`(     cat $limfile | grep "95% expected band :"    | awk '{print $9}')`
      else
        MeanExpLimit=99.
        MedianExpLimit=99.
        ExpLim68Down=99.
        ExpLim68Up=99.
        ExpLim95Down=99.
        ExpLim95Up=99.
      fi
    fi 
    #echo $mass $ObsLimit $MeanExpLimit $MedianExpLimit $ExpLim68Down $ExpLim68Up $ExpLim95Down $ExpLim95Up >> $LimSummary
    echo $mass $ObsLimit $MeanExpLimit $MedianExpLimit $ExpLim95Down $ExpLim68Down $ExpLim68Up $ExpLim95Up >> $LimSummary
  done

# echo $LimSummary
# cat $LimSummary
 

}

# ------------------------ PLOT LIMIT --------------------------------------- 
plt_limit()
{
  source /localgrid/xjanssen/root_5.28.00b/root/bin/thisroot.sh
  LimFig=$LimitName'_'$MethodLimit
  limfile=LimitResults/$LimitName/$LimitName'_'$MethodLimit'.bands.summary'
  root -l -q src/PlotLimit.C++"(\"$limfile\",\"$LimFig\",\"$LimTitle\",$DoObsLimit,$DoExpLimit)" &
}

#----------------------------------------------------------------------------------
#------------------------ DO EVERYTHING NO ---------------------------------------
#----------------------------------------------------------------------------------

pwd

parse_config
if [ $sub -eq 1 ] ; then
  sub_limit
fi
if [ $get -eq 1 ] ; then
  get_limit
fi
if [ $plt -eq 1 ] ; then
  plt_limit
fi



