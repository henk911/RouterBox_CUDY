// Visual regression checks use the real browser DOM and the actual LuCI view.
// Run ui-smoke with CUDYROUTE_WRITE_FIXTURE=1 and ui-preview before this test.
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
const path=require('node:path');
function rgb(s){return s.match(/[\d.]+/g).slice(0,3).map(Number);}
function luminance(c){return rgb(c).map(v=>v/255).map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4).reduce((v,c,i)=>v+c*[.2126,.7152,.0722][i],0);}
function contrast(a,b){const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CUDYROUTE_BROWSER||undefined,args:['--no-sandbox']});
 try{
  for(const theme of ['dark','light']){
   const context=await browser.newContext({viewport:{width:1366,height:950},colorScheme:theme==='dark'?'light':'dark'});
   const page=await context.newPage();
   await page.goto('file://'+path.resolve('output/playwright/preview.html'));
   await page.evaluate(theme=>{document.body.style.backgroundColor=theme==='dark'?'#222':'#f4f6fa';document.body.style.color=theme==='dark'?'#ccc':'#202a3c';window.cudyroutePage.update(window.cudyroutePage.state);},theme);
   assert.equal(await page.locator('.rb-app').getAttribute('data-rb-theme'),theme,'must follow LuCI, not OS preference');
   const colors=await page.locator('.rb-card').first().evaluate(card=>({background:getComputedStyle(card).backgroundColor,text:getComputedStyle(card).color,title:getComputedStyle(card.querySelector('h3')).color}));
   assert(contrast(colors.background,colors.text)>=4.5,JSON.stringify(colors));
   assert(contrast(colors.background,colors.title)>=4.5,JSON.stringify(colors));
   const toolbar=await page.locator('.rb-toolbar').evaluate(el=>({background:getComputedStyle(el).backgroundColor,text:getComputedStyle(el).color}));
   assert(contrast(toolbar.background,toolbar.text)>=4.5,JSON.stringify(toolbar));
   await page.screenshot({path:'output/playwright/theme-'+theme+'.png',fullPage:true});
   await page.evaluate(()=>window.cudyroutePage.subscriptionDialog());
   const dialog=await page.locator('.modal.rb-modal').evaluate(el=>({theme:el.getAttribute('data-rb-theme'),background:getComputedStyle(el).backgroundColor,text:getComputedStyle(el).color}));
   assert.equal(dialog.theme,theme);
   assert(contrast(dialog.background,dialog.text)>=4.5,JSON.stringify(dialog));
   const field=await page.locator('.rb-dialog input:not([type=checkbox])').first().evaluate(el=>({background:getComputedStyle(el).backgroundColor,text:getComputedStyle(el).color}));
   assert(contrast(field.background,field.text)>=4.5,JSON.stringify(field));
   await page.screenshot({path:'output/playwright/theme-'+theme+'-dialog.png',fullPage:true});
   await page.setViewportSize({width:390,height:844});
   await page.screenshot({path:'output/playwright/theme-'+theme+'-mobile.png',fullPage:true});
   await page.evaluate(()=>window.ui?.hideModal?.());
   await context.close();
   console.log(theme+': cards, toolbar, headings and dialog fields meet 4.5:1 contrast; opposite OS scheme tested');
  }
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
