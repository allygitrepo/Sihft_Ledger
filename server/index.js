const express = require("express");
const sequelize = require("./config/db");
require("dotenv").config();
const routes = require("./modules/Routes");
const app = express();

app.use(express.json());


// PostgreSQL connect test
(async () => {
    try {
        await sequelize.authenticate();
        console.log("Database connected!");
    } catch (err) {
        console.error("DB error:", err);
    }
})();

// creates table if not exists
sequelize
    .sync({ alter: true })   // Use alter instead of force to avoid dropping tables
    .then(() => console.log("Tables synced!"))
    .catch((err) => console.log("Error syncing DB:", err));


app.use("/shiftledger", routes);
app.get("/", (req, res) => {
    res.json(
        {
            status: "Running",
            server: "Shiftledger"
        }
    )
});


app.listen(process.env.PORT, () => {
    console.log(`Server is running on port ${process.env.PORT}`);
});