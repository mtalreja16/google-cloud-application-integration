const $hostname =  window.location.hostname ;
const $alertContainer = $('.alert-container');
const $form = $('form');
const $visaComponents = $(".visaComponents");
const $cashComponents = $(".cashComponents");
const $vanModel = $('.van-model');
const $vanDRent = $('.day-rent');

$visaComponents.hide();
$alertContainer.hide();


$vanModel[0].innerText += ` ${sessionStorage.getItem('vanTitle')}`;
$vanDRent[0].innerText += sessionStorage.getItem('vanDRent') + "$/day";

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
  document.getElementById("email").value = "mtalreja@google.com";
  document.getElementById("name").value = "John Snow";
  document.getElementById("state").value = "CA";
  document.getElementById("licenseid").value = "JS500GB";
  document.getElementById("dob").value = "2000-01-01";
  document.getElementById("full-name").value = "John Snow";  
  document.getElementById("phone").value = "8478676660";
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
  data.name = document.getElementById("full-name").value;
  data.state = document.getElementById("state").value;
  data.licenseid = document.getElementById("licenseid").value;
  data.dob = document.getElementById("dob").value;
  data.sku_id =  ` ${sessionStorage.getItem('vanTitle')}`;
  data.rate = sessionStorage.getItem('vanDRent');
  data.taxamount = sessionStorage.getItem('vanDRent');
  data.totalamount = sessionStorage.getItem('vanDRent');
  data.depositamount = sessionStorage.getItem('vanDRent');
  data.gender = 1;
  data.vanid = sessionStorage.getItem('vanID');
  var play = JSON.stringify(data);


  fetch('https://' + $hostname + '/run?name=manage-reservation&trigger=createReservation', {
    method: 'POST',
    body: JSON.stringify({
      "reservation-payload": play
    }),
    headers: {
      'Content-Type': 'application/json'
    }
  }).then(response => response.json())
  .then(data => {
    var out = JSON.stringify(data);
    if(data.executionId!=null)
    {
        
      $alertContainer.append(
        `<div class="alert alert-success mb-4" role="alert">
          <h5 class="alert-heading">Order Successful!</h5>
          <p class="mb-0">An email will be sent to you within 30 minutes with the order details. <br>
            Thank you for choosing Cymbal Van Rentals.
            ${out}
          </p>
        </div>`);
       document.getElementById("fillform").style.display="none";
       $alertContainer.show();
       $alertContainer[0].scrollIntoView(); 
    }
    else
    {
      $alertContainer.append(
        ` 
        <div class="alert alert-danger mb-4" role="alert">
        <h5 class="alert-heading">Ohhh no, we ran into issue, try later!</h5>
          <p class="mb-0">${out}</p>
        </div>`);

       $alertContainer.show();
       $alertContainer[0].scrollIntoView(); 

    }
    
  })
  .catch(err => {
    $alertContainer.append(
      ` 
      <div class="alert alert-danger mb-4" role="alert">
      <h5 class="alert-heading">Ohhh no, we ran into issue, try later!</h5>
        <p class="mb-0"></p>
      </div>`);

     $alertContainer.show();
     $alertContainer[0].scrollIntoView(); 
  });

});