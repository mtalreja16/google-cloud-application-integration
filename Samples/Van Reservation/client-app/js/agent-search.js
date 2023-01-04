   function submitVanPickedup(id) {
    var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
   fetch('https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=manage-reservation&trigger=pickupVan', {
      method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}",
        "reservationid": data.id + ".0"
      }),
      headers: {
        'Content-Type': 'application/json'
      }
      }).then(response => response.json())
        .then(data => {});
    }


    function submitVanReturned(id) {
      var data = JSON.parse( ` ${sessionStorage.getItem(id)} `)
    // Prevent the form from submitting and refreshing the page
    fetch('https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=manage-reservation&trigger=returnVan', {
      method: 'POST',
      body: JSON.stringify({
        "reservation-payload": "{}",
        "reservationid": data.id + ".0"
      }),
      headers: {
        'Content-Type': 'application/json'
      }
      }).then(response => response.json())
        .then(data => {});
    }

    // When the search button is clicked
  $('#searchButton').click(function(e) {
    // Prevent the form from submitting and refreshing the page
    e.preventDefault();
    fetch('https://integration-lib-eiiwtomg2a-uc.a.run.app/run?project=integration-demo-364406&region=us-west1&name=manage-reservation&trigger=manage-reservation_API_1', {
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

          let html = '<table class="table"><tr>';

          // Add table headers
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
              html += `<td><a href="#" onclick=viewDetails('true','${myid}');>Van Pickup </a></td>`
            }
            else if(dataPoint.status == 'Fulfilled'){
              html += `<td><a href="#" onclick=viewDetails('false','${myid}');>Van Return </a></td>`
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
        html += `<tr><td>Add Notes: </td><td><input type=text></input></td></tr>`;
        html += `<tr><td>Upload Pictures: </td><td><input type=file></input></td></tr>`;
        html += '</table>';
        if(pickup == 'true')
        {
          footerhtml =  `<button type="button" class="btn btn-secondary" onclick="submitVanPickedup('${id}')" id="vanpickup">Van Pickedup</button>`
        }
        else
        {
          footerhtml =  `<button type="button" class="btn btn-secondary" onclick="submitVanReturned('${id}')"id="vanreturn">Van Returned</button>`
        }
        // Set modal content
        $('#modalContent').html(html);
        $('#modelfooter').html(footerhtml);
        // Open Bootstrap modal
        $('#myModal').modal('show');
    }
