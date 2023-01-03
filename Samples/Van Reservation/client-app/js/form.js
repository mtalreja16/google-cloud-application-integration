const $alertContainer = $('.alert-container');
const $form = $('form');
const $visaComponents = $(".visaComponents");
const $cashComponents = $(".cashComponents");
const $vanModel = $('.van-model');
const $vanDRent = $('.day-rent');
const $vanMRent = $('.month-rent');

$visaComponents.hide();
$alertContainer.hide();


$vanModel[0].innerText += ` ${sessionStorage.getItem('vanTitle')}`;
$vanDRent[0].innerText += sessionStorage.getItem('vanDRent') + "/day";
$vanMRent[0].innerText += sessionStorage.getItem('vanMRent') + "/month";

if(sessionStorage.getItem('vanTitle') === null) {
  $('form').remove();

  $('footer').before(`
  <div class="jumbotron bg-danger text-white">
    <div class="container">
      <h1 class="display-4">No Van Ordered</h1>
      <p class="lead">Please reserve a van to be able to view this page</p>
    </div>
  </div>`);
}

$("#visaRBTN").click(function() { 
  $(this).addClass('active'); //Act as radio buttons
  $visaComponents.slideDown('slow');
});


window.onload = function() {
  document.getElementById("pickupdate").value = "2022-10-28";
  document.getElementById("dropoffdate").value = "2022-11-03";
  document.getElementById("configuration").value = "GPS";
  document.getElementById("card").value = "1234-5678-9101-1121";
  document.getElementById("expiry").value = "2025-01-01";
  document.getElementById("expiry2").value = "2025-01-01";
  document.getElementById("cvv").value = "123";
  document.getElementById("email").value = "manojtrek@gmail.com";
  document.getElementById("name").value = "Manoj Talreja";
  document.getElementById("state").value = "CA";
  document.getElementById("licenseid").value = "JS500GB";
  document.getElementById("dob").value = "2000-01-01";
  document.getElementById("full-name").value = "Manoj Talreja";  
  document.getElementById("phone").value = "3479676660";
  document.getElementById("pickup-loc").value = "CA";
}  

$form.submit(function(e) {
  e.preventDefault();
  var data = {};
  // Collect field data
  data.pickupdate = document.getElementById("pickupdate").value;
  data.dropoffdate = document.getElementById("dropoffdate").value;
  data.configuration = document.getElementById("configuration").value;
  data.card = document.getElementById("card").value;
  data.expiry = document.getElementById("expiry").value;
  data.cvv = document.getElementById("cvv").value;
  data.email = document.getElementById("email").value;
  data.name = document.getElementById("name").value;
  data.state = document.getElementById("state").value;
  data.licenseid = document.getElementById("licenseid").value;
  data.dob = document.getElementById("dob").value;
  data.sku_id =  ` ${sessionStorage.getItem('vanTitle')}`;
  data.rate = sessionStorage.getItem('vanDRent');
  data.taxamount = sessionStorage.getItem('vanDRent');
  data.totalamount = sessionStorage.getItem('vanMRent');
  data.depositamount = sessionStorage.getItem('vanDRent');
  data.gender = 1;
  var play = JSON.stringify(data);


  fetch('https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=reservation-demo2&trigger=reservation-demo_API_1', {
    method: 'POST',
    body: JSON.stringify({
      "Operation": "POST",
      "reservation-payload": play
    }),
    headers: {
      'Content-Type': 'application/json'
    }
  }).then(response => response.json())
  .then(data => {
    $alertContainer.show();
    $alertContainer[0].scrollIntoView(); // Use index to be able to use vanilla JS DOM functions
    
  })
  .catch(err => {
    console.error(err);
  });

});