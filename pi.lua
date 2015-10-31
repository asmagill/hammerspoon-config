-- Further cleaned up and made into a useful? function... doesn't return last 5 digits
-- of calculation; suppresses formatting and extra verbiage when y and z == 0
--
-- Example to test hs.javascript. This is a modified version of the code found at
-- http://www.trans4mind.com/personal_development/JavaScript/longnumPiMachin.htm
--
-- Note that the last 5 digits are probably wrong (this returns 5 more digits than
-- requested), but the specified N digits are provably correct (see web page for
-- details)
--
-- This results in the following on my machine:
--
--     true	PI (10005)=3.
--     14159 26535 89793 23846 26433 83279 50288 41971 69399 37510 (50)
--     58209 74944 59230 78164 06286 20899 86280 34825 34211 70679 (100)
--       ... cut for brevity ...
--     26456 00162 37428 80210 92764 57931 06579 22955 24988 72758 (9950)
--     46101 26483 69998 92256 95968 81592 05600 10165 52563 75678 (10000)
--     56672
--     Win PI=
--     3.1415926535897932384626433832795
--     It took: 1.672 seconds
pi = function(x, y, z)
    x = x or 100
    y = y or 0
    z = z or 0

    local s, v = hs.javascript([[
    mess="";
    //10^11 seems to be the maximum
    //too high a figure for the base introduces errors
    Base=Math.pow(10,11);
    //num digits in each array item
    cellSize=Math.floor(Math.log(Base)/Math.LN10);
    //below is not used in this script
    a=Number.MAX_VALUE;
    MaxDiv=Math.floor(Math.sqrt(a));

    function makeArray (n, aX, Integer) {
      var i=0;
      for (i=1; i<n; i++)
      aX[i] = null;
      aX[0] = Integer;
    }

    function isEmpty (aX) {
      var empty=true
      for (i=0; i<aX.length; i++)
      if (aX[i]) {
        empty= false;
        break;
      }
      return empty;
    }

    //junior school math
    function Add (n, aX, aY) {
      carry=0
      for (i=n-1; i>=0; i--) {
        aX[i] += Number(aY[i])+Number(carry);
        if (aX[i]<Base)
          carry = 0;
        else {
          carry = 1;
          aX[i] =Number(aX[i])- Number(Base);
        }
      }
    }

    //subtract
    function Sub (n, aX, aY) {
      for (i=n-1; i>=0; i--) {
        aX[i] -= aY[i];
        if (aX[i]<0) {
          if (i>0) {
            aX[i] += Base;
            aX[i-1]--;
          }
        }
      }
    }

    //multiply big number by "small" number
    function Mul (n, aX, iMult) {
      carry=0;
      for (i=n-1; i>=0; i--) {
        prod = (aX[i])*iMult;
        prod += carry;
        if (prod>=Base) {
          carry = Math.floor(prod/Base);
          prod -= (carry*Base);
        } else
          carry = 0;
        aX[i] = prod;
      }
    }

    //divide big number by "small" number
    function Div (n, aX, iDiv, aY) {
      carry=0;
      for (i=0; i<n; i++) {
        //add any previous carry
        currVal = Number(aX[i])+Number(carry*Base);
        //divide
        theDiv =Math.floor(currVal/iDiv);
        //find next carry
        carry = currVal-theDiv*iDiv;
        //put the result of division in the current slot
        aY[i] = theDiv;
      }
    }

    //compute arctan
    function arctan (iAng, n, aX) {
      iAng_squared=iAng*iAng;
      k=3; //k is the coefficient in the series 2n-1, 3,5..
      sign=0;
      makeArray (n, aX, 0); //aX is aArctan
      makeArray (n, aAngle, 1);
      Div (n, aAngle, iAng, aAngle); //aAngle = 1/iAng, eg 1/5
      Add (n, aX, aAngle); // aX = aAngle or long angle
      while (!isEmpty(aAngle)) {
        Div (n, aAngle, iAng_squared, aAngle); //aAngle=aAngle/iAng_squared, iAng_squared is iAng*iAng
        //mess+="iAng="+iAng+"; aAngle="+aAngle+"<br>";
        Div (n, aAngle, k, aDivK); /* aDivK = aAngle/k */
        if (sign)
          Add (n, aX, aDivK); /* aX = aX+aDivK */
        else
          Sub (n, aX, aDivK); /* aX = aX-aDivK */
        k+=2;
        sign = 1-sign;
      }
      mess+="aArctan="+aArctan+"<br>";
    }

    // Calculate pi
    function calcPI (numDec, cbCount, cbSpace) {
      var ans="";
      t1=new Date();
      numDec=Number(numDec)+5;
      iAng=new Array(10);
      coeff=new Array(10);
      arrayLength=Math.ceil(1+numDec/cellSize);
      aPI = new Array(arrayLength);
      aArctan = new Array(arrayLength);
      aAngle=new Array(arrayLength);
      aDivK=new Array(arrayLength);
      //Pi/4 = 4*arctan(1/5)-arctan(1/239)
      //coeff is an array of the coefficients
      //the last item is 0!
      coeff[0] = 4;
      coeff[1] = -1;
      coeff[2] = 0;
      //iAng holds the angles, 5 for 1/5, etc
      iAng[0] = 5;
      iAng[1] = 239;
      iAng[2] = 0;
      makeArray (arrayLength, aPI, 0);
      //Machin: Pi/4 = 4*arctan(1/5)-arctan(1/239)
      makeArray(arrayLength,aAngle,0);
      makeArray(arrayLength,aDivK,0);
      for (var i=0; coeff[i]!=0; i++) {
        arctan(iAng[i], arrayLength, aArctan);
        //multiply by coefficients of arctan
        Mul (arrayLength, aArctan, Math.abs(coeff[i]));
        //mess+="mi="+coeff[i]+"<br>";
        if (coeff[i]>0)
          Add (arrayLength, aPI, aArctan);
        else
          Sub (arrayLength, aPI, aArctan);
        //mess+="api="+aPI+"<br>";
      }
      //we have calculated pi/4, so need to finally multiply
      Mul (arrayLength, aPI, 4);
      //we have now calculated PI, and need to format the answer
      //to print it out
      sPI="";
      tempPI="";
      //put the figures in the array into the string tempPI
      for (i=0;i<aPI.length;i++) {
        aPI[i]=String(aPI[i]);
        //ensure there are enough digits in each cell
        //if not, pad with leading zeros
        if (aPI[i].length<cellSize&&i!=0) {
          while (aPI[i].length<cellSize)
            aPI[i]="0"+aPI[i];
        }
        tempPI+=aPI[i];
      }
      //now put the characters into the string sPI
      for (i=0;i<=numDec-5;i++) {
        //put the 3 on a different line, and add a decimal point
        if (i==0)
          if (cbSpace == 1 || cbCount == 1)
            sPI+=tempPI.charAt(i)+".\n";
          else
            sPI+=tempPI.charAt(i)+".";
        else {
          //split the long line up into manageable rows
    //       if (document.getElementById("cbCount").checked)
          if (cbCount == 1)
            addcount=" ("+(i)+")";
          else
            addcount="";
    //       if (document.getElementById("cbSpace").checked)
          if (cbSpace == 1)
            thespace=" ";
          else
            thespace="";
          if ((i)%50==0&&i!=0&&cbCount==1)
            sPI+=tempPI.charAt(i)+addcount+"\n";
          else
            if (i%5==0)
              sPI+=tempPI.charAt(i)+thespace;
            else
              sPI+=tempPI.charAt(i);
        }//i not zero
      }
      //now put the print-out together
      //print our pi
      ans+=("PI ("+numDec+")="+sPI+"\n");
      //Window's calculator Pi (for confirmation);
      ans+=("Win PI=\n3.1415926535897932384626433832795\n");
      t2=new Date();
      timeTaken=(t2.getTime()-t1.getTime())/1000;
      ans+="It took: "+timeTaken+" seconds";
      //document.write(mess);
      //   var myDiv=document.getElementById("d1");
      //   myDiv.innerHTML=ans;
      if (cbSpace == 1 || cbCount == 1)
        return ans;
      else
        return sPI;
    }

    calcPI(]]..tostring(x)..[[, ]]..tostring(y)..[[, ]]..tostring(z)..[[) ;
    ]]
    )

    if s then return v end

    error(inspect(v))
end
