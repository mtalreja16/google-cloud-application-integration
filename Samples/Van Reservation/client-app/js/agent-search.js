const $alertContainer = $('.alert-container');
const $url = 'https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=manage-reservation'
const $resumeurl = 'https://integration-lib-eiiwtomg2a-uc.a.run.app/resume?project=integration-demo-364406&region=us-west1&name=manage-reservation'

function submitVanPickedup(id) {
    var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
    console.log(data)
   fetch($url + '&trigger=pickupVan', {
      method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}",
        "reservationid": data.id + ".0"
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
              `<div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
                <p class="mb-0">Van Pickup was complete!!
                  ${out}
                </p>
              </div>`);
            $alertContainer.show();
             $alertContainer[0].scrollIntoView(); 
             $('#searchButton').click();
          }
          else
          {
            $alertContainer.append(
              `<div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
              <h5 class="alert-heading">Ohhh no, we ran into issue, try again later!</h5>
                <p class="mb-0">${out}</p>
              </div>`);
             $alertContainer.show();
             $alertContainer[0].scrollIntoView(); 
      }
      });
      
    }


  function submitVanReturned(id) {
      var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
      var claim = 'NA';
      if(document.getElementById("Resend").checked)
      {
        claim = 'Process'
      }
      // Prevent the form from submitting and refreshing the page
    fetch($url + '&trigger=returnVan', {
      method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}",
        "reservationid": data.id + ".0",
        "processclaim": claim
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
          `<div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
            <p class="mb-0">Van Return was complete!!
              ${out}
            </p>
          </div>`);
         $alertContainer.show();
         $alertContainer[0].scrollIntoView(); 
         $('#searchButton').click();
      }
      else
      {
        $alertContainer.append(
          ` <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
            <p class="mb-0"> Ohhh no, we ran into issue, try again later! ${out}</p>
          </div>`);
         $alertContainer.show();
         $alertContainer[0].scrollIntoView(); 
      }
    });
  }

  function submitApproveRequest(id) {
    var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
    // Prevent the form from submitting and refreshing the page
    fetch($resumeurl + '&executionId=' + data.execution_id, {
      method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}",
        "reservationid": data.id + ".0"
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    }).then(response => response.json())
    .then(data => {
      var out = JSON.stringify(data);
    
    if(data.eventExecutionInfoId!=null)
    {
      $alertContainer.append(
        `<div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <p class="mb-0">Van Return was complete!!
            ${out}
          </p>
        </div>`);
       $alertContainer.show();
       $alertContainer[0].scrollIntoView(); 
       $('#searchButton').click();
    }
    else
    {
      $alertContainer.append(
        ` <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <p class="mb-0"> Ohhh no, we ran into issue, try again later! ${out}</p>
        </div>`);
       $alertContainer.show();
       $alertContainer[0].scrollIntoView(); 
    }
  });
  }
    // When the search button is clicked
  $('#searchButton').click(function(e) {
    // Prevent the form from submitting and refreshing the page
    e.preventDefault();
    fetch($url + '&trigger=getReservation', {
    method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}"
      }),
      headers: {
        'Content-Type': 'application/json'
      }
      }).then(response => response.json())
        .then(data => {
          // Extract data points from payload
          console.log(JSON.stringify(data.outputParameters));
          if(data.outputParameters.reservations == '')
          {
            const div = document.getElementById('searchResults');
            div.innerHTML = "<p>No reservations found!!</p>";
            return;
          }
          const dataPoints = data.outputParameters.reservations;

          let html = '<table class="table table-sm"><tr>';

          // Add table headers
          html += '<th> # </th>';
          html += '<th>Name</th>';
          html += '<th>Email</th>';
          html += '<th>License ID</th>';
          html += '<th>SKU ID</th>';
          html += '<th>Pickup Date</th>';
          html += '<th>Dropoff Date</th>';
          html += '<th>Status</th>';
          html += '<th>Action</th>';
          html += '</tr>';
          
          // Add table rows
          dataPoints.forEach(dataPoint => {
            html += '<tr>';
            html += `<td >${dataPoint.id}</td>`;
            html += `<td id="recordId">${dataPoint.name}</td>`;
            html += `<td>${dataPoint.email}</td>`;
            html += `<td>${dataPoint.licenseid}</td>`;
            html += `<td>${dataPoint.sku_id}</td>`;
            html += `<td>${dataPoint.pickupdate}</td>`;
            html += `<td>${dataPoint.dropoffdate}</td>`;
            html += `<td>${dataPoint.status}</td>`;
            sessionStorage.setItem('myitem-' + dataPoint.id, JSON.stringify(dataPoint))
            var myid = 'myitem-' + dataPoint.id;
            if(dataPoint.status == 'Reserved'){
              html += `<td><a href="#" onclick=viewDetails('Reserved','${myid}');>Van Pickup </a></td>`
            }
            else if(dataPoint.status == 'Fulfilled'){
              html += `<td><a href="#" onclick=viewDetails('Fulfilled','${myid}');>Van Return </a></td>`
            }
            else if(dataPoint.status == 'Initiated'){
              html += `<td><a href="#" onclick=viewDetails('Initiated','${myid}');>Approve Reservation </a></td>`
            }
            html += '</tr>';
          });

          html += '</table>';
          // Add HTML table to div element
          const div = document.getElementById('searchResults');
          div.innerHTML = html;
        });
      });
  
  function viewDetails(pickup, id) {
        // Parse data object from string
        var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
        let html = '<table>';
        // Add table rows
        Object.entries(data).forEach(([key, value]) => {
          html += `<tr><td>${key}:</td><td>${value}</td></tr>`;
        });
        if(pickup == 'Reserved')
        {
          html += `<tr><td>Add Notes: </td><td><textarea type=text class="form-cntrol"></textarea></td></tr>`;
          html += `<tr><td>Upload Pictures: </td><td><input type=file></input></td></tr>`;
          footerhtml =  `<button type="button" class="btn btn-secondary"  data-dismiss="modal" onclick="submitVanPickedup('${id}')" id="vanpickup">Van Pickedup</button>`
        }
        else if(pickup == 'Fulfilled')
        {
          html += `<tr><td>Add Notes: </td><td><textarea type=text class="form-cntrol"></textarea></td></tr>`;
          html += `<tr><td>Upload Pictures: </td><td><input type=file></input></td></tr>`;
          html += `<tr><td>Process for Claims </td><td><div class="bootstrap-switch-square">
                    <input type="checkbox" data-toggle="switch" name="Resend" id="Resend" />
                  </div></td></tr>`;
          footerhtml =  `<button type="button" class="btn btn-secondary"  data-dismiss="modal" onclick="submitVanReturned('${id}')" id="vanreturn">Van Returned</button>`
        }
        else
        {
          footerhtml =  `<button type="button" class="btn btn-secondary"  data-dismiss="modal" onclick="submitApproveRequest('${id}')" id="reservationconfirm">Reservation Confirmed</button>`
        }
        html += '</table>';
        // Set modal content
        $('#modalContent').html(html);
        $('#modelfooter').html(footerhtml);
        // Open Bootstrap modal
        $('#myModal').modal('show');
    }
