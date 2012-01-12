
#include <stdio.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <string>
#include <vector>


#include <TFile.h>
#include <TGraphAsymmErrors.h>

//#include "bandUtils.cxx"

void extractLimit( string LimSummary , TString filename , TString bandsname , bool DoObsLim , bool DoExpLim ){

  TFile*      bands = new TFile(bandsname,"RECREATE"); 

  if        ( DoObsLim && DoExpLim ) {
    makeBands(bands, "hww", filename ,0,false,0);  
  } else if ( DoObsLim ) {
    makeBands(bands, "hww", filename ,0,false,1);
  } else if ( DoExpLim ) {
    makeBands(bands, "hww", filename ,0,false,2);
  }

  bands->Write();

  vector<float> vMass           ;
  vector<float> vObsLimit       ;
  vector<float> vMeanExpLimit   ;
  vector<float> vMedianExpLimit ;
  vector<float> vExpLim68Down   ;
  vector<float> vExpLim68Up     ;
  vector<float> vExpLim95Down   ; 
  vector<float> vExpLim95Up     ;

  bool          FillMass(true) ;
  if ( DoObsLim ) {
    TGraphAsymmErrors *obs    = (TGraphAsymmErrors*) bands->Get("hww_obs");
    for ( int iMass = 0 ; iMass < obs->GetN() ; ++iMass ) {
      vMass       .push_back( obs->GetX()[iMass] );
      vObsLimit   .push_back( obs->GetY()[iMass] );
    } 
    FillMass = false ;
  }

   bool useMeanBand = false;

  if ( DoExpLim ) {
    TGraphAsymmErrors *mean68 = (TGraphAsymmErrors*) bands->Get("hww_median");
    TGraphAsymmErrors *mean95 = (TGraphAsymmErrors*) bands->Get("hww_median_95");
    TGraphAsymmErrors *median68 = (TGraphAsymmErrors*) bands->Get("hww_median");
    TGraphAsymmErrors *median95 = (TGraphAsymmErrors*) bands->Get("hww_median_95");
    for ( int iMass = 0 ; iMass < mean68->GetN() ; ++iMass ) {
      if (FillMass) vMass       .push_back( mean >GetX()[iMass] );
      vMeanExpLimit   .push_back( mean68->GetY()[iMass] ) ;
      vMedianExpLimit .push_back( median68->GetY()[iMass] ) ;
      if (useMeanBand) {
        vExpLim95Down   .push_back( mean68->GetY()[iMass] - mean95->GetErrorYlow(iMass)  );
        vExpLim68Down   .push_back( mean68->GetY()[iMass] - mean68->GetErrorYlow(iMass)  );
        vExpLim68Up     .push_back( mean68->GetY()[iMass] + mean68->GetErrorYhigh(iMass) );
        vExpLim95Up     .push_back( mean68->GetY()[iMass] + mean95->GetErrorYhigh(iMass) );
      } else {
        vExpLim95Down   .push_back( median68->GetY()[iMass] - median95->GetErrorYlow(iMass)  );
        vExpLim68Down   .push_back( median68->GetY()[iMass] - median68->GetErrorYlow(iMass)  );
        vExpLim68Up     .push_back( median68->GetY()[iMass] + median68->GetErrorYhigh(iMass) );
        vExpLim95Up     .push_back( median68->GetY()[iMass] + median95->GetErrorYhigh(iMass) );
      }
    }
    FillMass = false ;
  }

  // Fill vectors if not Obs and Exp with dummy values are requested
  if ( ! DoObsLim ) {
    for ( int iMass = 0 ; iMass < vMass.size() ; ++iMass ) vObsLimit.push_back(99.);  
  }
  if ( ! DoExpLim ) {
    for ( int iMass = 0 ; iMass < vMass.size() ; ++iMass ) {
      vMeanExpLimit   .push_back(99.);
      vMedianExpLimit .push_back(99.);
      vExpLim68Down   .push_back(99.);
      vExpLim68Up     .push_back(99.);
      vExpLim95Down   .push_back(99.);
      vExpLim95Up     .push_back(99.);
    }
  }

  // Write final results
  ofstream OutFile;
  OutFile.open (LimSummary.c_str());
  for ( int iMass = 0 ; iMass < vMass.size() ; ++iMass ) {
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


  printBand(bands, "hww",LimSummary+"_utils");


  bands->Close(); 
}
