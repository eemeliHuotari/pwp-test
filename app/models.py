"""Models for the application."""
from django.core.validators import MinValueValidator
from django.db import models


class Serializable:
    """Provides serialize functionality"""
    # pylint: disable=too-few-public-methods

    def serialize(self, short=False):
        """
        Converts a model instance to a python dictionary to use for JSON

        Args:
            short: If True, excludes some related objects

        Returns:
            dict: Dictionary representation of the model instance
        """
        raise NotImplementedError("Must implement serialize method")


# Create your models here.
class User(models.Model):
    """Represents a user/client that can make orders and reservations."""
    name = models.CharField(max_length=64, unique=True)

    class Meta:
        """Meta options for the User model."""
        ordering = ["name"]


class Table(models.Model):
    """Represents a table in the restaurant."""
    min_people = models.IntegerField()
    max_people = models.IntegerField()

    class Meta:
        """Meta options for the Table model."""
        ordering = ["id"]


class MenuItem(models.Model, Serializable):
    """Represents a menu item that can be ordered."""
    name = models.CharField(max_length=64, unique=True)
    description = models.CharField(max_length=64)
    type = models.CharField(max_length=20, default="main course")
    price = models.FloatField()

    class Meta:
        ordering = ["name"]


class OrderItem(models.Model, Serializable):
    """Represents an item in an order."""
    item = models.ForeignKey(MenuItem, on_delete=models.CASCADE)
    amount = models.IntegerField()
    order = models.ForeignKey(
        "Order", on_delete=models.CASCADE, related_name="order_items", null=True
    )

    def __str__(self):
        return f"{self.item} - {self.amount} pcs"

    class Meta:
        ordering = ["id"]


class Order(models.Model, Serializable):
    """Represents an order made by a user."""
    status = models.CharField(max_length=64)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="orders")

       class Meta:
        ordering = ["id"]


class Reservation(models.Model, Serializable):
    """Represents a table reservation made by a user."""
    number_of_people = models.IntegerField(validators=[MinValueValidator(1)])
    date_and_time = models.DateTimeField()
    duration = models.DurationField()

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="reservations"
    )
    table = models.ForeignKey(
        Table, on_delete=models.CASCADE, related_name="reservations"
    )

    class Meta:
        ordering = ["date_and_time"]

    # def clean(self):
    #     """Ensure table capacity is suitable for the reservation"""
    #     if hasattr(self, "table"):
    #         if self.number_of_people < self.table.min_people:
    #             raise ValidationError(
    #                 f"Too few people for this table. Minimum required: {self.table.min_people}."
    #             )
    #         if self.number_of_people > self.table.max_people:
    #             raise ValidationError(
    #                 f"Too many people for this table. Maximum allowed: {self.table.max_people}."
    #             )

    #         self._ensure_no_overlap()

    # def _ensure_no_overlap(self):
    #     """Ensure that the reservation does not overlap with an existing reservation"""
    #     end_time = self.date_and_time + self.duration
    #     overlapping = (
    #         Reservation.objects.filter(table=self.table)
    #         .filter(
    #             date_and_time__lt=end_time,
    #             date_and_time__gte=(self.date_and_time - models.F("duration")),
    #         )
    #         .exclude(id=self.id)
    #     )

    #     if overlapping.exists():
    #         raise ValidationError("Reservation overlaps with existing reservations")

    # def save(self, *args, **kwargs):
    #     """Run validation before saving the reservation"""
    #     self.clean()  # Call clean() to validate
    #     super().save(*args, **kwargs)
