window.onload = function(e) {

 
const $vandCollection = $('.vand-collection');
fetch('https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=manage-reservation&trigger=getinventory', {
   method: 'POST',
   body: JSON.stringify({
    "reservation-payload": "{}",
    "reservationid": "0.0"
  }),
   headers: {
     'Content-Type': 'application/json'
   }
   }).then(response => response.json())
     .then(data => { 
      const vans = data.outputParameters.vanlist;
      vans.forEach(van => {
        var text = ""
        if(!van.reserved){
           text = `
           <label class="vand-text"> ${van.rentperday}</label>$/day &nbsp;&nbsp;&nbsp;&nbsp;
           <label class="vand-text"> ${van.rentpermonth}</label>$/Month
           <a href="form.html" type="button" class="btn btn-primary " onclick="setselectedValue('${van.brand} ${van.model}','${van.rentperday}')" id="btn-reserve">Reserve</a>`
        }
        else{
           text = `
          <div class="form-group">
           <input type="text" class="form-control form-control-sm" placeholder="emai@email.com"> </input>
         </div>
           <div class="form-group">
           <div class="form-check">
             <input class="form-check-input" type="checkbox" id="gridCheck">
             <label class="form-check-label" for="gridCheck"> Notify Me</label>
           </div>`
        }
        $vandCollection.append(`
        <div class="col-12 col-md-6 col-lg-4">
          <div class="vand my-2 ${van.type}" data-van="${van.type}">
            <img src="${van.image}" class="vand-img-top">
            <div class="vand-body">
              <h5 class="vand-title font-weight-bold">${van.brand} ${van.model}</h5>
              <p class="vand-text text-muted font-weight-light">${van.description}</p>
              <hr>
              ${text}
            </div>
          </div>
        </div>`);}
        )});
      }

//Code that adds the vans in the above array to the vand-collection

function setselectedValue(title, rent) 
{
  sessionStorage.setItem('vanTitle', title);
  sessionStorage.setItem('vanDRent', rent);
}

// const $reserveButtons = $('.btn-reserve'); // will use later

const $vanFilter = $('#filter'); //had to use none jQuery selector for...
$('#filter').click(() => {
  let vanType = $vanFilter[0].options[$vanFilter[0].selectedIndex].value; // Use index to be able to use vanilla JS DOM functions

  // We have to access the parent elements since if we didn't we'll be left with an empty vand taking space in the page.
  if (vanType === 'family') {
    $('.vand').parent().hide();
    $('div[data-van="family-van"]').parent().show();
  } else if (vanType === "sport") {
    $('.vand').parent().hide();
    $('div[data-van="sport-van"]').parent().show();
  } else 
    $('.vand').parent().show();
});
