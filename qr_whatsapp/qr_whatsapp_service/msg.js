
// const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const { logger, logger_all } = require('./logger')
// const qrcode = require('qrcode-terminal');
// const qrcode_img = require('qrcode');
// const util = require("util")
//           const client = new Client({
//             restartOnAuthFail: true,
//             takeoverOnConflict: true,
//             takeoverTimeoutMs: 0,
//             puppeteer: {
//               handleSIGINT: false,
//               args: [
//                 '--no-sandbox',
//                 '--disable-setuid-sandbox',
//                 '--disable-dev-shm-usage',
//                 '--disable-accelerated-2d-canvas',
//                 '--no-first-run',
//                 '--no-zygote',
//                 '--disable-gpu'
//               ],
//               executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
//             },
//             authStrategy: new LocalAuth(
//               { clientId: 'test' }
//             )
//           }
  
//           );
  
//           client.initialize();
//           client.on('qr', async (qr) => {
//             // Generate and scan this code with your phone
//             logger_all.info(" [get QR code success response] : " + qr);
//             qrcode.generate(qr, { small: true });
//           });

//           client.on('authenticated', async (data) => {
//             logger_all.info(" [Client is Log in] : " + JSON.stringify(data));
  
//           });
//           if (!client.pupPage) {
//             // client has not been initialized
//           }
  
//           client.on('ready', async (data) => {
//             logger_all.info(" [Client is ready] : " + client.info.pushname);
//             logger_all.info(util.inspect(client))
//             await client.getChats().then(async (chats) => {
//               console.log(chats.id._serialized)
//             })
  
//           });
  
        
// const qr = require('qrcode');

// var url ="http://localhost/test/index.php?user_id=3"

// qr.toFile('/Applications/XAMPP/htdocs/test/user_3.png', url, (err) => {
//   if (err) throw err;

// });



// var zone = ["Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","Zone-2","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-3","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","zone-4","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5","Zone-5"]

// var parliment = ["Kakinada","Kakinada","Kakinada","Kakinada","Kakinada","Kakinada","Amalapuram","Amalapuram","Amalapuram","Amalapuram","Amalapuram","Amalapuram","Amalapuram","Rajahmundry","Rajahmundry","Rajahmundry","Rajahmundry","Rajahmundry","Rajahmundry","Rajahmundry","Narsapuram","Narsapuram","Narsapuram","Narsapuram","Narsapuram","Narsapuram","Narsapuram","Eluru","Eluru","Eluru","Eluru","Eluru","Eluru","Eluru","Machilipatnam","Machilipatnam","Machilipatnam","Machilipatnam","Machilipatnam","Machilipatnam","Machilipatnam","Vijayawada","Vijayawada","Vijayawada","Vijayawada","Vijayawada","Vijayawada","Vijayawada","Guntur","Guntur","Guntur","Guntur","Guntur","Guntur","Guntur","Narasaraopet","Narasaraopet","Narasaraopet","Narasaraopet","Narasaraopet","Narasaraopet","Narasaraopet","Bapatla","Bapatla","Bapatla","Bapatla","Bapatla","Bapatla","Bapatla","Ongole","Ongole","Ongole","Ongole","Ongole","Ongole","Ongole","Nellore","Nellore","Nellore","Nellore","Nellore","Nellore","Nellore","Tirupati","Tirupati","Tirupati","Tirupati","Tirupati","Tirupati","Tirupati","Chittoor","Chittoor","Chittoor","Chittoor","Chittoor","Chittoor","Chittoor","Rajampet","Rajampet","Rajampet","Rajampet","Rajampet","Rajampet","Rajampet","Kadapa","Kadapa","Kadapa","Kadapa","Kadapa","Kadapa","Kadapa","Anantapur","Anantapur","Anantapur","Anantapur","Anantapur","Anantapur","Anantapur","Hindupur","Hindupur","Hindupur","Hindupur","Hindupur","Hindupur","Hindupur","Kurnool","Kurnool","Kurnool","Kurnool","Kurnool","Kurnool","Kurnool","Nandyal","Nandyal","Nandyal","Nandyal","Nandyal","Nandyal","Nandyal"]


// var consti = ["Prathipad","Pithapuram","Kakinada Rural","Peddapuram","Kakinada City","Jaggampeta","Ramachandrapuram","Mummidivaram","Amalapuram","Razole","Gannavaram (Eg)","Kothapeta","Mandapeta","Anaparthy","Rajanagaram","Rajahmundry City","Rajahmundry Rural","Kovvur","Nidadavole","Gopalpuram","Achanta","Palacole","Narasapur","Bhimavaram","Undi","Tanuku","Tadepalligudem","Ungutur","Dendulur","Eluru","Polavaram","Chintalapudi","Nuzvid","Kaikalur","Gannavaram(Krishna)","Gudivada","Pedana","Machilipatnam","Avanigadda","Pamarru","Penamaluru","Tiruvuru","VijayawadaWest","VijayawadaCentral","VijayawadaEast","Mylavaram","Nandigama","Jaggayyapet","Tadikonda","Mangalagiri","Ponnur","Tenali","Prathipadu","Guntur West","Guntur East","Peddakurapadu","Chilakaluripet","Narasaraopet","Sattenapalli","Vinukonda","Gurzala","Macherla","Vemuru","Repalle","Bapatla","Parchur","Addanki","Chirala","Santhanuthalapadu","Yerragondapalem","Darsi","Ongole","Kondepi","Markapur","Giddalur","Kanigiri","Kandukur","Kavali","Atmakur","Kovur","Nellore City","Nellore Rural","Udayagiri","Sarvepalli","Gudur","Sullurpet","Venkatagiri","Tirupati","Srikalahasti","Satyavedu","Chandragiri","Nagari","GangadharaNellore","Chittoor","Puthalapattu","Palamaner","Kuppam","Rajampet","Kodur","Rayachoty","Thamballapalle","Pileru","Madanpalle","Punganur","Badvel","Kadapa","Pulivendla","Kamalapuram","Jammalamadugu","Proddatur","Mydukur","Rayadurg","Uravakonda","Guntakal","Tadpatri","Singanamala","Anantapur Urban","Kalyandurg","Raptadu","Madakasira","Hindupur","Penukonda","Puttaparthi","Dharmavaram","Kadiri","Kurnool","Pattikonda","Kodumur","Yemmiganur","Mantralayam","Adoni","Alur","Allagadda","Srisailam","Nandikotkur","Panyam","Nandyal","Banaganapalle","Dhone"]

// var link = ["https://chat.whatsapp.com/Jn0QJB1ihJwEoUzGCAxwyj","https://chat.whatsapp.com/CGkYGnKr0ltI9CHRADDIje","https://chat.whatsapp.com/JO8xjxKN34X9FIOlzts0fJ","https://chat.whatsapp.com/Gw2wTvbK2L3JmusaaTFNGK","https://chat.whatsapp.com/HiemubPv1kHIXMxq1bnnLq","https://chat.whatsapp.com/Jsh4AmKGQQG0Ac6mMV9DLK","https://chat.whatsapp.com/DSPT1HQ5wMf6F26BmBJ3pV","https://chat.whatsapp.com/Lve4YTkMPm55GelAt2QB4Y","https://chat.whatsapp.com/GW4ihUUab2LCzYNtvqgfbf","https://chat.whatsapp.com/ET1g2KhGszJDhUqXf0rPqr","https://chat.whatsapp.com/DTzIQwLOwZO1S2BdmIJ0ED","https://chat.whatsapp.com/C9loFDrdeLO8Evx9tUtQWq","https://chat.whatsapp.com/IIBrWpFuDzD8TJ8UVXPIYn","https://chat.whatsapp.com/FwTe4oVCk2N3VKNTP2cqs2","https://chat.whatsapp.com/J9DyrhwiFzP0jpHolPapQE","https://chat.whatsapp.com/JtB7Jk61kxI4LLFMJWKzXv","https://chat.whatsapp.com/D3cd7fAXq5FGeoLN04pajx","https://chat.whatsapp.com/DM17gu6pvBS44zbNZlKWMA","https://chat.whatsapp.com/JJgPLrnQim0DzMW0ULiGwi","https://chat.whatsapp.com/JSl3UIL96QwEpNIwCRr6I3","https://chat.whatsapp.com/BsHWhsyYBbJHA6IfdIg1hS","https://chat.whatsapp.com/F3qperQh2G2DciRbow8SZ1","https://chat.whatsapp.com/EkBYhAaHjidBTNF0Nn9qPc","https://chat.whatsapp.com/CCXmgWdNPvrJzeA5JzEEON","https://chat.whatsapp.com/IpW5sqou0zKA268qp24mvK","https://chat.whatsapp.com/BKTak0wI8c0BWHK1mtvfQW","https://chat.whatsapp.com/L3MD7f6m0Do4vLT9sYHa7f","https://chat.whatsapp.com/Bo9GDzA9W550P1gPMyllpE","https://chat.whatsapp.com/GVDqnpBs1ow1UKpl6WyrT2","https://chat.whatsapp.com/E4wwsdNMudi7fMo13U2CSm","https://chat.whatsapp.com/F2fF4qfwTJr2jjG3YZTSde","https://chat.whatsapp.com/JoHp5AVRfNs0bWouep8to1","https://chat.whatsapp.com/IPjgNKYnTlnI5JpMh790dx","https://chat.whatsapp.com/KOA0ejiG90X1fgeULb5nIH","https://chat.whatsapp.com/LQqTIAM220Z2TlelZ7UWY2","https://chat.whatsapp.com/Jo9Fq1IDH2kJv3DXzoJ9K2","https://chat.whatsapp.com/EM0uUtXcIrZHPwd0UyzBsO","https://chat.whatsapp.com/HdELY2tIG970Q8hOiWbsCh","https://chat.whatsapp.com/EYDX51A7EVf9EgmcKeTToQ","https://chat.whatsapp.com/H2XCjm5fiWSEdIyx3gCgQ2","https://chat.whatsapp.com/IhDDIzYeo21Bl8qEkwZmWj","https://chat.whatsapp.com/JN6Pr7EZYK4559QdIaFGrw","https://chat.whatsapp.com/BVBwfyXDljcDt6IeIph5ut","https://chat.whatsapp.com/EnJPIk799Wk6UQCe37jIKx","https://chat.whatsapp.com/Hju1GAMyrwq5qLq9FQHVR5","https://chat.whatsapp.com/CWk6Hpk3iO0CXttbJb4zuy","https://chat.whatsapp.com/I036XJ4NIP4JjsOThEad5i","https://chat.whatsapp.com/FsjP12sC8V48DgXRIa4bXh","https://chat.whatsapp.com/FunC38tKXtR4fV0sbFo7dE","https://chat.whatsapp.com/COqdyBN1d0EGh0LXA9XTZT","https://chat.whatsapp.com/F9wg1iTRnF8EKxpqBOoICc","https://chat.whatsapp.com/BdslQtlyCPR9LCfnhyqQJf","https://chat.whatsapp.com/Ir7wehzbSq14CeLN38TMYh","https://chat.whatsapp.com/GwQytrs40bZ4feMRwRRDcf","https://chat.whatsapp.com/KVpHDqiThSc3IRWgXxUpeq","https://chat.whatsapp.com/Ljt52eS1qE05305IMx1N8Q","https://chat.whatsapp.com/JiM6lhzEGTbEyR7CeDPjZ4","https://chat.whatsapp.com/J0LSDR7or8fLSikIxM6qDY","https://chat.whatsapp.com/IttG90HG8nCCmwRFpOREk0","https://chat.whatsapp.com/GrqxLugShtQ37s81Eg7yz5","https://chat.whatsapp.com/FvjcLFnXpdk8vTKBm8NkIj","https://chat.whatsapp.com/D2eQnVIXbBs9yrXQRYP0R4","https://chat.whatsapp.com/IiciREYMIXeGR8EhT77SU4","https://chat.whatsapp.com/JosaLfwMz559G8WpfHlyNi","https://chat.whatsapp.com/CSpSQCnnqhI1wFSMAZZms1","https://chat.whatsapp.com/DQ2Q8VVnS5kIzxuGoAQpkq","https://chat.whatsapp.com/KtUy2Tza1n3JQzUKdlOhGz","https://chat.whatsapp.com/Li6x4RRjRJI5XgXallg9sY","https://chat.whatsapp.com/Ijes6Zy2NtH6gE0QeyH6jB","https://chat.whatsapp.com/IrV2JBmL8Dd5jAOOWDF8SE","https://chat.whatsapp.com/GY9yJAW2TMXKWsLON876ea","https://chat.whatsapp.com/En9cJiQWMev7Dr2GgPvmpb","https://chat.whatsapp.com/IPFFHPW1FyUDsMmVda5375","https://chat.whatsapp.com/BwCCFeIiaf9H59ANrmzyFO","https://chat.whatsapp.com/KGc9HhObOWYLlV1WtN1rFA","https://chat.whatsapp.com/G4B6ObpmX0O5oV29f9zFxj","https://chat.whatsapp.com/LoY6ccHQU0NDGmfsVkTkFn","https://chat.whatsapp.com/E6DFOyc3C1rKUpy4NjBchL","https://chat.whatsapp.com/ITd2tEmTbBgK8ryxnByvYI","https://chat.whatsapp.com/HkAfSw6768aGygoBPqnZPT","https://chat.whatsapp.com/HAwysyZyVC144HXFHQetOw","https://chat.whatsapp.com/LKhi6bS5mWICRoQQ9s42dL","https://chat.whatsapp.com/HAkXJwxokkyFkyBMFaB2eP","https://chat.whatsapp.com/FkjfDy64j731vr6Ue9w6oz","https://chat.whatsapp.com/LjeCNZkZsIz5lcrV7ZToMA","https://chat.whatsapp.com/G3x5NybHMupCCIFYEgICFp","https://chat.whatsapp.com/H14rIjLJ5cC5qSYpaRiNgm","https://chat.whatsapp.com/GUVKRQ951fz1egd899qh0I","https://chat.whatsapp.com/IeB7APOTB4jEbTE1alTSei","https://chat.whatsapp.com/Fbd8POXtMBfEhnXwXFCJp4","https://chat.whatsapp.com/KXS8oXk5eSZIb5hm2jhaBF","https://chat.whatsapp.com/JGmP8VCSi042LF6ho209WF","https://chat.whatsapp.com/KUBOzH7rWmNHQJ3bY7swMO","https://chat.whatsapp.com/Cen8o4Nuf8028SNrSCrZjE","https://chat.whatsapp.com/CgP0SaFef1P2UlhaE4tDKv","https://chat.whatsapp.com/GpazYmOiHbsGcxy9BpL1Jr","https://chat.whatsapp.com/I6t5nLyYVQAAx56dfNV0OW","https://chat.whatsapp.com/CTnhP3A88TLBum5onA425k","https://chat.whatsapp.com/L74D4juMYeTDBKhxapkUCt","https://chat.whatsapp.com/L06H3ykQsgMEH3o46KYQDP","https://chat.whatsapp.com/DlWYhOoMpot3TFiJQCzVXF","https://chat.whatsapp.com/CeAJ0ldxrFNHnKLSZ77JAh","https://chat.whatsapp.com/Ewf1KdcvDdQ39l4iwJrEpE","https://chat.whatsapp.com/FIoxMReTQUfHdBkYIfCTKR","https://chat.whatsapp.com/Bv54FZdl0POFN7G3nxk4mM","https://chat.whatsapp.com/D4ZGFhk8LQO3Wtk9fvf0Lq","https://chat.whatsapp.com/HoqEpUjRE8L4hvXAx8gl25","https://chat.whatsapp.com/DVYtEj7pomVKjOLIxC04pH","https://chat.whatsapp.com/HNerhmFJ5ll0YHqdcvnJpE","https://chat.whatsapp.com/EF7YTNJReIK30Z0moGTrjx","https://chat.whatsapp.com/KxIkw5okKyw486G63gCy0J","https://chat.whatsapp.com/IhmpzGfEMCyEG5yCB3xF4u","https://chat.whatsapp.com/IvBpAbOrMIrGxBPb6EeT8x","https://chat.whatsapp.com/HYHoCGUQW54Ds5mxtgtLZl","https://chat.whatsapp.com/LeoxRJiIjGS1kqeYCqvxSK","https://chat.whatsapp.com/ED7JYGlKzrOBwrdusv2qtb","https://chat.whatsapp.com/Ei5SzxUPeN66Wf3rTGAbPM","https://chat.whatsapp.com/EyB80QOKipHLkXXjezYaDr","https://chat.whatsapp.com/Eg6D6ddz9dPH01RFhZ8HxS","https://chat.whatsapp.com/IanZUnAZx9BHHUZFAauyJF","https://chat.whatsapp.com/LmDrIr5IPYAC8Eyab2faTy","https://chat.whatsapp.com/IULd7pvXR5VKgRZwRGzwQC","https://chat.whatsapp.com/Hqi4K7tPhrvKHNYMMEvtKs","https://chat.whatsapp.com/D2fjPkXALfD0qiTSzWzjDX","https://chat.whatsapp.com/LTct2d0DZ1hCiIYWGIG8Xy","https://chat.whatsapp.com/Ca0VAKVPpLBCk1vsnWP4f7","https://chat.whatsapp.com/H5mIZEQwVHY9LKOl8ISymP","https://chat.whatsapp.com/BrbYRtyPQxHBx4CltuAxQF","https://chat.whatsapp.com/CoxixMHjo9j2ehz8CqAQ5d","https://chat.whatsapp.com/CQVvlSnHtar4LjoFw4Hsgp","https://chat.whatsapp.com/IKDjTaE6kjV5cKRYsTyK5D","https://chat.whatsapp.com/Hn1eXb9Luty3rPWsuiqb6y","https://chat.whatsapp.com/C3QxIgM4U6SHawlg4qsIlw","https://chat.whatsapp.com/BH2O3Bosi9y9C9ylMiphUy","https://chat.whatsapp.com/Gt3usbXNRLx13dL4zV5GZH","https://chat.whatsapp.com/IxRL2T359RdLoN1PTaMnis","https://chat.whatsapp.com/LwEE7FudzjfL52Bc9vHIRd","https://chat.whatsapp.com/CQxStr9vziNL8pllGF4iHx","https://chat.whatsapp.com/IoBRGkjjE1w7MBIlIePGtc"]

var parl = [1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,7,7,7,7,8,8,8,8,8,8,8,9,9,9,9,9,9,9,10,10,10,10,10,10,10,11,11,11,11,11,11,11,12,12,12,12,12,12,12,13,13,13,13,13,13,13,14,14,14,14,14,14,14,15,15,15,15,15,15,15,16,16,16,16,16,16,16,17,17,17,17,17,17,17,18,18,18,18,18,18,18,19,19,19,19,19,19,19,20,20,20,20,20,20,20,21,21,21,21,21,21,21,22,22,22,22,22,22,22,23,23,23,23,23,23,23,24,24,24,24,24,24,24,25,25,25,25,25,25,25]
var consti = ["Palakonda","Kurupam","Parvathipuram","Salur","ArakuValley","Paderu","Rampachodavaram","Ichapuram","Palasa","Tekkali","Pathapatnam","Srikakulam","Amadalavalasa","Narasannapeta","Etcherla","Rajam","Bobbili","Cheepurupalli","Gajapathinagaram","Nellimarla","Vizianagaram","Srungavarapukota","Bhimili","VisakhapatnamEast","VisakhapatnamSouth","VisakhapatnamNorth","VisakhapatnamWest","Gajuwaka","Chodavaram","Madugula","Anakapalli","Pendurthi","Elamanchili","Payakaraopeta","Narsipatnam","Tuni","Prathipad","Pithapuram","Kakinada Rural","Peddapuram","Kakinada City","Jaggampeta","Ramachandrapuram","Mummidivaram","Amalapuram","Razole","Gannavaram (Eg)","Kothapeta","Mandapeta","Anaparthy","Rajanagaram","Rajahmundry City","Rajahmundry Rural","Kovvur","Nidadavole","Gopalpuram","Achanta","Palacole","Narasapur","Bhimavaram","Undi","Tanuku","Tadepalligudem","Ungutur","Dendulur","Eluru","Polavaram","Chintalapudi","Nuzvid","Kaikalur","Gannavaram(Krishna)","Gudivada","Pedana","Machilipatnam","Avanigadda","Pamarru","Penamaluru","Tiruvuru","VijayawadaWest","VijayawadaCentral","VijayawadaEast","Mylavaram","Nandigama","Jaggayyapet","Tadikonda","Mangalagiri","Ponnur","Tenali","Prathipadu","Guntur West","Guntur East","Peddakurapadu","Chilakaluripet","Narasaraopet","Sattenapalli","Vinukonda","Gurzala","Macherla","Vemuru","Repalle","Bapatla","Parchur","Addanki","Chirala","Santhanuthalapadu","Yerragondapalem","Darsi","Ongole","Kondepi","Markapur","Giddalur","Kanigiri","Kandukur","Kavali","Atmakur","Kovur","Nellore City","Nellore Rural","Udayagiri","Sarvepalli","Gudur","Sullurpet","Venkatagiri","Tirupati","Srikalahasti","Satyavedu","Chandragiri","Nagari","GangadharaNellore","Chittoor","Puthalapattu","Palamaner","Kuppam","Rajampet","Kodur","Rayachoty","Thamballapalle","Pileru","Madanpalle","Punganur","Badvel","Kadapa","Pulivendla","Kamalapuram","Jammalamadugu","Proddatur","Mydukur","Rayadurg","Uravakonda","Guntakal","Tadpatri","Singanamala","Anantapur Urban","Kalyandurg","Raptadu","Madakasira","Hindupur","Penukonda","Puttaparthi","Dharmavaram","Kadiri","Kurnool","Pattikonda","Kodumur","Yemmiganur","Mantralayam","Adoni","Alur","Allagadda","Srisailam","Nandikotkur","Panyam","Nandyal","Banaganapalle","Dhone"]

var query = `INSERT INTO public.master_constituency(
   parl_id,consti_name,consti_status,consti_entry_date)
 VALUES`
for(var i=0; i<parl.length;i++){

   query = query +` ( ${parl[i]}, '${consti[i]}','Y', CURRENT_TIMESTAMP),`

}
logger.info(query)
