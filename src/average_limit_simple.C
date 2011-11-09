#include <stdio.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;

void average_limit_simple ( string LimSummary , string LimSumBase , 
                            bool DoObsLim , int ObsSplitStart , int ObsSplitEnd , 
                            bool DoExpLim , int ExpSplitStart , int ExpSplitEnd
                          ) {

  bool          FirstFile(true) ;
  float         nObsLimit(0)    ;
  float         nExpLimit(0)    ;
  vector<float> vMass           ;
  vector<float> vObsLimit       ;
  vector<float> vMeanExpLimit   ;
  vector<float> vMedianExpLimit ;
  vector<float> vExpLim68Down   ;
  vector<float> vExpLim68Up     ;
  vector<float> vExpLim95Down   ; 
  vector<float> vExpLim95Up     ;

  if ( DoObsLim ) {
    for ( int iJob = ObsSplitStart ; iJob <= ObsSplitEnd ; ++iJob ) {
      ostringstream File ;
      File  << LimSumBase << iJob << ".summary" ;
      ifstream indata;
      indata.open(File.str().c_str());
      if(!indata) { // file couldn't be opened
        cerr << "Error: file could not be opened: " << File.str().c_str()  << endl;
        continue;
      } 
      int   iMass(0)       ;
      float Mass           ;
      float ObsLimit       ;
      float MeanExpLimit   ;
      float MedianExpLimit ;
      float ExpLim68Down   ;
      float ExpLim68Up     ;
      float ExpLim95Down   ;
      float ExpLim95Up     ;
      while ( indata >> Mass >> ObsLimit >> MeanExpLimit >> MedianExpLimit >> ExpLim95Down >> ExpLim68Down >> ExpLim68Up >> ExpLim95Up )  {
        //cout << Mass << " " << ObsLimit << endl;
        if ( FirstFile )     { vMass.push_back(Mass) ; }
        if ( nObsLimit == 0 ){ vObsLimit.push_back(ObsLimit); } 
        else                 { vObsLimit.at(iMass) += ObsLimit ; } 
        ++iMass; 
      }
      ++nObsLimit; 
      FirstFile = false ;
    }
    if (nObsLimit>0) {
      for ( int iMass = 0 ; iMass < (signed) vMass.size() ; ++iMass ) {
        vObsLimit.at(iMass) /= nObsLimit ;
        //cout << vMass.at(iMass) << " --> Average " <<  vObsLimit.at(iMass) << endl;
      }
    }

  }

  if ( DoExpLim ) {
    for ( int iJob = ExpSplitStart ; iJob <= ExpSplitEnd ; ++iJob ) {
      ostringstream File ;
      File  << LimSumBase << iJob << ".summary" ;
      ifstream indata;
      indata.open(File.str().c_str());
      if(!indata) { // file couldn't be opened
        cerr << "Error: file could not be opened: " << File.str().c_str()  << endl;
        continue;
      } 
      int   iMass(0)       ;
      float Mass           ;
      float ObsLimit       ;
      float MeanExpLimit   ;
      float MedianExpLimit ;
      float ExpLim68Down   ;
      float ExpLim68Up     ;
      float ExpLim95Down   ;
      float ExpLim95Up     ;
      while ( indata >> Mass >> ObsLimit >> MeanExpLimit >> MedianExpLimit >> ExpLim95Down >> ExpLim68Down >> ExpLim68Up >> ExpLim95Up )  {
        //cout << Mass << " " << MeanExpLimit << endl;
        if ( FirstFile )     { vMass.push_back(Mass) ; }
        if ( nExpLimit == 0 ){ 
          vMeanExpLimit   .push_back(MeanExpLimit   );
          vMedianExpLimit .push_back(MedianExpLimit );
          vExpLim68Down   .push_back(ExpLim68Down   );
          vExpLim68Up     .push_back(ExpLim68Up     );
          vExpLim95Down   .push_back(ExpLim95Down   );
          vExpLim95Up     .push_back(ExpLim95Up     );
        } else { 
          vMeanExpLimit   .at(iMass) += MeanExpLimit   ;
          vMedianExpLimit .at(iMass) += MedianExpLimit ;
          vExpLim68Down   .at(iMass) += ExpLim68Down   ;
          vExpLim68Up     .at(iMass) += ExpLim68Up     ;
          vExpLim95Down   .at(iMass) += ExpLim95Down   ;
          vExpLim95Up     .at(iMass) += ExpLim95Up     ;
        } 
        ++iMass; 
      }
      ++nExpLimit; 
      FirstFile = false ;
    }
    if (nExpLimit>0) {
      for ( int iMass = 0 ; iMass < (signed) vMass.size() ; ++iMass ) {
        vMeanExpLimit   .at(iMass) /= nExpLimit ;
        vMedianExpLimit .at(iMass) /= nExpLimit ;
        vExpLim68Down   .at(iMass) /= nExpLimit ;
        vExpLim68Up     .at(iMass) /= nExpLimit ;
        vExpLim95Down   .at(iMass) /= nExpLimit ;
        vExpLim95Up     .at(iMass) /= nExpLimit ;
        //cout << vMass.at(iMass) << " --> Average " <<  vMeanExpLimit.at(iMass) << endl;
      }
    } 
  }

  // Fill vectors if not Obs and Exp with dummy values are requested
  if ( ! DoObsLim ) {
    for ( int iMass = 0 ; iMass < (signed) vMass.size() ; ++iMass ) vObsLimit.push_back(99.);  
  }
  if ( ! DoExpLim ) {
    for ( int iMass = 0 ; iMass < (signed) vMass.size() ; ++iMass ) {
      vMeanExpLimit   .push_back(99.);
      vMedianExpLimit .push_back(99.);
      vExpLim68Down   .push_back(99.);
      vExpLim68Up     .push_back(99.);
      vExpLim95Down   .push_back(99.);
      vExpLim95Up     .push_back(99.);
    }
  }

  // Write final avergaged results
  ofstream OutFile;
  OutFile.open (LimSummary.c_str());
  for ( int iMass = 0 ; iMass < (signed) vMass.size() ; ++iMass ) {
    OutFile <<        vMass.at(iMass)
            << " " << vObsLimit.at(iMass)  
            << " " << vMeanExpLimit.at(iMass) 
            << " " << vMedianExpLimit.at(iMass)
            << " " << vExpLim95Down.at(iMass) 
            << " " << vExpLim68Down.at(iMass) 
            << " " << vExpLim68Up.at(iMass) 
            << " " << vExpLim95Up.at(iMass)
            << "\n" ;
  }
  OutFile.close();
  cout << LimSummary.c_str() << endl;
  return;
}

