
#include <systick.h>
#include <rcc.h>

typedef struct {
    volatile uint16 CR1;
    uint16  RESERVED0;
    volatile uint16 CR2;
    uint16  RESERVED1;
    volatile uint16 SMCR;
    uint16  RESERVED2;
    volatile uint16 DIER;
    uint16  RESERVED3;
    volatile uint16 SR;
    uint16  RESERVED4;
    volatile uint16 EGR;
    uint16  RESERVED5;
    volatile uint16 CCMR1;
    uint16  RESERVED6;
    volatile uint16 CCMR2;
    uint16  RESERVED7;
    volatile uint16 CCER;
    uint16  RESERVED8;
    volatile uint16 CNT;
    uint16  RESERVED9;
    volatile uint16 PSC;
    uint16  RESERVED10;
    volatile uint16 ARR;
    uint16  RESERVED11;
    volatile uint16 RCR;
    uint16  RESERVED12;
    volatile uint16 CCR1;
    uint16  RESERVED13;
    volatile uint16 CCR2;
    uint16  RESERVED14;
    volatile uint16 CCR3;
    uint16  RESERVED15;
    volatile uint16 CCR4;
    uint16  RESERVED16;
    volatile uint16 BDTR;   // Not used in general purpose timers
    uint16  RESERVED17;     // Not used in general purpose timers
    volatile uint16 DCR;
    uint16  RESERVED18;
    volatile uint16 DMAR;
    uint16  RESERVED19;
} Timer;


Timer* timer2=  (Timer*)TIMER2_BASE;



// The setup() method runs once, when the sketch starts
void setup()   {                
    SerialUSB.println("Entering Setup");
  // initialize the digital pin as an output:


// init timer 
rcc_enable_clk_timer2();
rcc_enable_clk_gpioa();
// CH1 is connected to TI1 input
timer2->CR2 = BIT(7) ;


// page 353: overall description of PWM INPUT for TIMx
// page 384: CCER map and description
// page 389: map of all the fields position
// CC1S, CC2S:  Compare/Capture 1/2 Set
// IC - input capture event
/* a Rising pulse on Pin D2 triggers:
      a counter copy from CNT to CCR1
      HIGH on the slave controller. which is configured to reset CNT
  then a falling pulse triggers:
      counter copy from CNT to CCR2
    
    rinse and repeat. which mean we have to read CCR1 and CCR2 before the next rising pulse
    
    notes: 
    both CC need to have TI1 as a source of event (CCxS  S for source)
    but opposite polarity (CCxP   P for polarity)
  */  

// disable everything, for some reason it's enabled and registers are read only when enabled
timer2->CCER = 0  ; 
timer2->CR1=0;

// reset to make sure it's not wrongly initialized
timer2->CCMR1 = 0;
timer2->CCMR2 = 0;
// set CCMR1 CC1S to 01 (set active input TI1) 
/// 01: CC1 channel is configured as input, IC1 is mapped on TI1.
timer2->CCMR1 &= ~BIT(1);
timer2->CCMR1 |= BIT(0);
// set CCMR1 CC2S to 10 (set active input TI1) 
///  10: CC2 channel is configured as input, IC2 is mapped on TI1
timer2->CCMR1 |= BIT(9);
timer2->CCMR1 &= ~BIT(8);

// select the active polarity on TI1FP1. write CC1P to 0 (active on rising edge)
///0: non-inverted: capture is done on a rising edge of IC1. 
timer2->CCER &= ~BIT(5);
// select the active polarity on TI1FP2. write CC2P to 1 (active on falling edge)
///1: inverted: capture is done on a falling edge of IC1 
timer2->CCER |= BIT(1)  ;


//select valid trigger input: write TS to 101 in SMCR (Slave Mode Config Register). meaning we should reset when TI1 triggers
/// 101: Filtered Timer Input 1 (TI1FP1)
timer2->SMCR |= BIT(6) | BIT(4) ;
timer2->SMCR &= ~BIT(5);



// write SMS to 100 in SMCR: slave controller in reset mode
///100: Reset Mode - Rising edge of the selected trigger input (TRGI) reinitializes the counter and generates an update of the registers

timer2->SMCR &= ~BIT(0);
timer2->SMCR &= ~BIT(1) ;
timer2->SMCR |= BIT(2);


//enable CC modules
timer2->CCER |= (BIT0 | BIT4);
timer2->CR1 |= 1; // enable timer2
//timer2->DIER= BIT(2) | BIT(1) | BIT(0);

}



void readSonar() {
  const int pingPin= D2;

// reset CC counts
//timer2->CCR1=0;  
//timer2->CCR2=0;
// and status
//timer2->SR=0;



  pinMode(pingPin, OUTPUT);
  digitalWrite(pingPin, LOW); // ensure it is pulled low
  delayMicroseconds(2);
  digitalWrite(pingPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(pingPin, LOW);

//  initialize pin to receive pwm timing
  delayMicroseconds(2);
  pinMode(pingPin, INPUT);

// wait 40ms, the sonar spec ensure us a pulse will never be wider than 35ms and then only if nothing is detected. 25ms if something is detected
  delay(40);   


// wait for pin HIGH
 

    SerialUSB.println("\r\nDuration "); 
   SerialUSB.println(timer2->CR1);
    SerialUSB.println(timer2->CR2);
    SerialUSB.println(timer2->SMCR);
    SerialUSB.println(timer2->DIER);
    SerialUSB.println(timer2->SR);
    SerialUSB.println(timer2->EGR);
    SerialUSB.println(timer2->CCMR1);
    SerialUSB.println(timer2->CCMR2);
    SerialUSB.println(timer2->CCER);
    SerialUSB.println(timer2->PSC);
    
    SerialUSB.println(timer2->CCR1);
    SerialUSB.println(timer2->CCR2);
    SerialUSB.println(timer2->CNT);
    SerialUSB.print("\n"); 
}


void loop()                     
{
  SerialUSB.println("Entering Loop");
  delay(250); 
   readSonar();
  SerialUSB.println("End");    
}



