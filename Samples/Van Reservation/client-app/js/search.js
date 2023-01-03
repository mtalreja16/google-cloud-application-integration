//creating an array to insert vans images and info
const vanList = [
  {
    image: "img/image1.jpg",
    brand: "Thor Industries",
    model: 2018,
    type: "family-van",
    rentperday: 150,
    description: "Sleep 8, 32 Feet, Class A",
    rentpermonth: 1350,
  },
  {
    image: "img/image2.jpg",
    brand: "Mercedes Benz",
    model: 2012,
    type: "sport-van",
    rentperday: 175,
    description: "Sleep 6, 20 Feet, Class C",
    rentpermonth: 2500,
  },
  {
    image: "img/image3.jpg",
    brand: "Forest River",
    model: 2018,
    type: "sport-van",
    rentperday: 145,
    description: "Sleep 6, 20 Feet, Class C",
    rentpermonth: 1200,
  },
  {
    image: "img/image4.jpg",
    brand: "Winnebago",
    model: 2017,
    type: "family-van",
    rentperday: 155,
    description: "Sleep 8, 32 Feet, Class A",
    rentpermonth: 1360,
  },
  {
    image: "img/image5.jpg",
    brand: "Jayco",
    model: 2016,
    type: "family-van",
    rentperday: 140,
    description: "Sleep 8, 32 Feet, Class A",
    rentpermonth: 1150,
  },
  {
    image: "img/image6.jpg",
    brand: "Newmar",
    model: 2008,
    type: "sport-van",
    rentperday: 150,
    description: "Sleep 6, 20 Feet, Class C",
    rentpermonth: 1400,
  }
];

//Code that adds the vans in the above array to the vand-collection
const $vandCollection = $('.vand-collection');
vanList.forEach(van => {
  $vandCollection.append(`
  <div class="col-12 col-md-6 col-lg-4">
    <div class="vand my-2 ${van.type}" data-van="${van.type}">
      <img src="${van.image}" class="vand-img-top">
      <div class="vand-body">
        <h5 class="vand-title font-weight-bold">${van.brand} ${van.model}</h5>
        <p class="vand-text text-muted font-weight-light">${van.description}</p>
        <hr>
         <label class="vand-text"> ${van.rentperday}</label>/day &nbsp;&nbsp;&nbsp;&nbsp;
         <label class="vand-text"> ${van.rentpermonth}</label>/Month
        <a href="form.html" class="btn btn-outline-primary btn-reserve">Reserve</a>
      </div>
    </div>
  </div>
  `);
});

$('.btn-reserve').click(function(e) {
  let reservedVanTitle = $(this).parent().children()[0].innerText;
  let reservedVanDRent = $(this).parent().children()[3].innerText;
  let reservedVanMRent = $(this).parent().children()[4].innerText;

  sessionStorage.setItem('vanTitle', reservedVanTitle);
  sessionStorage.setItem('vanDRent', reservedVanDRent);
  sessionStorage.setItem('vanMRent', reservedVanMRent);
});

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
