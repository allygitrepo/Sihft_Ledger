const Company = require("./company.model");

const companyController = {
    create: async (req, res) => {
        try {
            const { company_name, industry_type, address, company_logo } = req.body;
            const owner_id = req.user.id; // From auth middleware

            if (!company_name || !industry_type) {
                return res.status(400).json({ message: "Company name and industry type are required" });
            }

            const company = await Company.create({
                owner_id,
                company_name,
                industry_type,
                address,
                company_logo
            });

            return res.status(201).json({ message: "Company created successfully", company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const owner_id = req.user.id;
            const companies = await Company.findAll({ where: { owner_id } });
            return res.status(200).json({ companies });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                return res.status(404).json({ message: "Company not found" });
            }

            return res.status(200).json({ company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const { company_name, industry_type, address, company_logo, status } = req.body;

            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                return res.status(404).json({ message: "Company not found" });
            }

            await company.update({
                company_name,
                industry_type,
                address,
                company_logo,
                status
            });

            return res.status(200).json({ message: "Company updated successfully", company });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const company = await Company.findOne({ where: { id, owner_id: req.user.id } });

            if (!company) {
                return res.status(404).json({ message: "Company not found" });
            }

            await company.destroy();
            return res.status(200).json({ message: "Company deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = companyController;
